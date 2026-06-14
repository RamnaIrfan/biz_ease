import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:biz_ease/screens/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/owner_service.dart';
import '../services/email_service.dart';
import '../models/owner_model.dart';
import 'owner_dashboard_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginBusinessPage extends StatefulWidget {
  const LoginBusinessPage({super.key});

  @override
  State<LoginBusinessPage> createState() => _LoginBusinessPageState();
}

class _LoginBusinessPageState extends State<LoginBusinessPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _loadSavedEmail();
  }

  Future<void> _loadSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('saved_business_email');
    if (savedEmail != null) {
      setState(() {
        usernameController.text = savedEmail;
      });
    }
  }

  Future<void> _saveEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_business_email', email);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 🔶 LOGO
            Image.asset("assets/welcome_logo.png", height: 280),
            const SizedBox(height: 1),

            // 🔶 TITLE
            const Text(
              "Please sign in as Business Owner",
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              "Manage your Business",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),

            // 🔶 USERNAME
            _inputField(
              "Enter your email",
              controller: usernameController,
            ),

            // 🔶 PASSWORD WITH EYE
            _inputField(
              "Enter your password",
              controller: passwordController,
              isPassword: true,
              showToggle: true,
            ),

            const SizedBox(height: 15),

            // 🔶 SIGN IN BUTTON
            _actionButton("SIGN IN", () async {
              String email = usernameController.text.trim();
              String password = passwordController.text.trim();

              if (email.isEmpty) {
                _showError("Please enter email");
                return;
              }

              if (password.isEmpty) {
                _showError("Please enter password");
                return;
              }

              try {
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                await authProvider.signInWithEmail(
                  email: email,
                  password: password,
                  userType: "business",
                );

                // Save email for next time
                await _saveEmail(email);

                // ✅ CHECK IF BUSINESS IS REGISTERED
                final ownerService = OwnerService();
                bool isRegistered = await ownerService.ownerExists(authProvider.userId!);

                if (context.mounted) {
                  if (isRegistered) {
                    // Direct access to Owner Dashboard
                    final owner = await ownerService.getOwner(authProvider.userId!);
                    if (owner != null && context.mounted) {
                      await _initiateMfaFlow(email, owner);
                    }
                  } else {
                    // Business not registered. Please sign up.
                    _showRegistrationPrompt();
                  }
                }
              } catch (e) {
                _showError(e.toString());
              }
            }),

            const SizedBox(height: 12),
            
            // 🔶 SIGN UP LINK
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/signupBusiness'),
              child: const Text(
                "Don't have account? Sign up here",
                style: TextStyle(color: Color(0xFFD88A1F)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔒 INITIATE MFA FLOW
  Future<void> _initiateMfaFlow(String email, OwnerModel owner) async {
    // 1. Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 2. Generate 6-digit code
      final code = (100000 + Random().nextInt(900000)).toString();

      // 3. Save to Firestore
      await FirebaseFirestore.instance.collection('mfa_codes').doc(email).set({
        'code': code,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 4. Send email
      final emailService = EmailService();
      await emailService.sendMfaCode(ownerEmail: email, code: code);

      if (context.mounted) {
        // Dismiss loading indicator
        Navigator.pop(context);
        
        // 5. Show OTP Dialog
        _showMfaDialog(email, owner);
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Dismiss loading
        _showError("Failed to initiate secure login: \$e");
      }
    }
  }

  // 🔒 SHOW MFA DIALOG
  void _showMfaDialog(String email, OwnerModel owner) {
    final TextEditingController otpController = TextEditingController();
    bool isVerifying = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("Secure Login"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Enter the 6-digit code sent to your email.", textAlign: TextAlign.center),
                const SizedBox(height: 20),
                TextField(
                  controller: otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    counterText: "",
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isVerifying ? null : () {
                  // User cancelled, sign them out
                  final authProvider = Provider.of<AuthProvider>(context, listen: false);
                  authProvider.signOut();
                  Navigator.pop(context);
                },
                child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD88A1F)),
                onPressed: isVerifying ? null : () async {
                  final enteredCode = otpController.text.trim();
                  if (enteredCode.length != 6) return;

                  setDialogState(() => isVerifying = true);

                  try {
                    final doc = await FirebaseFirestore.instance.collection('mfa_codes').doc(email).get();
                    
                    if (doc.exists && doc.data()!['code'] == enteredCode) {
                      // Code matches! Clean up and proceed
                      await FirebaseFirestore.instance.collection('mfa_codes').doc(email).delete();
                      
                      if (context.mounted) {
                        Navigator.pop(context); // Close dialog
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => OwnerDashboardPage(owner: owner),
                          ),
                        );
                      }
                    } else {
                      setDialogState(() => isVerifying = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Invalid or expired code"), backgroundColor: Colors.red),
                      );
                    }
                  } catch (e) {
                    setDialogState(() => isVerifying = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Error verifying code: \$e"), backgroundColor: Colors.red),
                    );
                  }
                },
                child: isVerifying
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("Verify", style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        }
      ),
    );
  }

  // 🔔 ERROR MESSAGE
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  // 🔔 REGISTRATION PROMPT
  void _showRegistrationPrompt() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Business not registered. Please sign up."),
        backgroundColor: const Color(0xFFD88A1F),
        action: SnackBarAction(
          label: "Sign up",
          textColor: Colors.white,
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/registerBusiness');
          },
        ),
      ),
    );
  }

  // 🔶 INPUT FIELD
  Widget _inputField(
    String hint, {
    required TextEditingController controller,
    bool isPassword = false,
    bool showToggle = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        obscureText: showToggle ? _obscurePassword : isPassword,
        cursorColor: const Color(0xFFD88A1F),
        decoration: InputDecoration(
          prefixIcon: Icon(
            isPassword ? Icons.lock : Icons.person,
            color: const Color(0xFFD88A1F),
          ),
          suffixIcon: showToggle
              ? IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: const Color(0xFFD88A1F),
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                )
              : null,
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFFD88A1F)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(color: Color(0xFFD88A1F)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide:
                const BorderSide(color: Color(0xFFD88A1F), width: 2),
          ),
        ),
      ),
    );
  }

  /// 🔶 FORGOT PASSWORD DIALOG
  void _showForgotPasswordDialog() {
    final TextEditingController resetEmailController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Reset Password"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Enter your registered email to receive a password reset link."),
            const SizedBox(height: 15),
            TextField(
              controller: resetEmailController,
              decoration: InputDecoration(
                hintText: "Email",
                prefixIcon: const Icon(Icons.email, color: Color(0xFFD88A1F)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFD88A1F)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFD88A1F), width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD88A1F)),
            onPressed: () async {
              final email = resetEmailController.text.trim();
              if (email.isEmpty) return;
              
              try {
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                await authProvider.resetPassword(email);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Reset link sent to your email! Check your inbox."),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text("Send Link", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // 🔶 BUTTON
  Widget _actionButton(String text, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFD88A1F),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        onPressed: onTap,
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}