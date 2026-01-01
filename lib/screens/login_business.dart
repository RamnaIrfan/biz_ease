import 'package:biz_ease/screens/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/owner_service.dart';
import 'owner_dashboard_page.dart';

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
              "Enter your username",
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

                // ✅ CHECK IF BUSINESS IS REGISTERED
                final ownerService = OwnerService();
                bool isRegistered = await ownerService.ownerExists(authProvider.userId!);

                if (context.mounted) {
                  if (isRegistered) {
                    // Direct access to Owner Dashboard
                    final owner = await ownerService.getOwner(authProvider.userId!);
                    if (owner != null && context.mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OwnerDashboardPage(owner: owner),
                        ),
                      );
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