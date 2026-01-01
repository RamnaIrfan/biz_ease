import 'package:biz_ease/screens/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/auth_state.dart';
import 'home_page.dart';  // ✅ ADD THIS IMPORT

class SignupCustomerPage extends StatefulWidget {
  const SignupCustomerPage({super.key});

  @override
  State<SignupCustomerPage> createState() => _SignupCustomerPageState();
}

class _SignupCustomerPageState extends State<SignupCustomerPage> {
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool _obscurePassword = true;

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red,
      ),
    );
  }


  void _showConfirmationDialog(String username, String email) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Signup Successful!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Welcome to BizEase! Here are your account details:'),
            const SizedBox(height: 16),
            Text('Name: $username', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('Email: $email', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text('You will be redirected to the home page shortly.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomePage()),
              );
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
Future<void> _onSignup() async {
  print("Sign up button pressed");
  
  String username = usernameController.text.trim();
  String email = emailController.text.trim();
  String password = passwordController.text.trim();

  if (username.isEmpty) {
    _showError("Please enter username");
    return;
  }

  if (email.isEmpty) {
    _showError("Please enter email");
    return;
  }

  if (!email.contains('@')) {
    _showError("Please enter a valid email address");
    return;
  }

  if (password.isEmpty) {
    _showError("Please enter password");
    return;
  }

  if (password.length < 6) {
    _showError("Password must contain at least 6 characters");
    return;
  }

  // Use AuthProvider to register with Firebase
  final authProvider = Provider.of<AuthProvider>(context, listen: false);
  try {
    await authProvider.signUpWithEmail(
      email: email,
      password: password,
      username: username,
      userType: 'customer',
    );

    // ✅ Update legacy AuthState for compatibility
    AuthState.isLoggedIn = true;
    AuthState.userType = 'customer';

    _showConfirmationDialog(username, email);

    Future.delayed(const Duration(milliseconds: 3000), () {
      if (context.mounted && Navigator.canPop(context)) {
        // If they haven't clicked OK yet, do it for them
        Navigator.of(context).popUntil((route) => route.isFirst);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const HomePage(),
          ),
        );
      }
    });
  } catch (e) {
    print("Signup error: $e");
    _showError(e.toString());
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFD88A1F),
        title: const Text('Customer Sign Up'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            /// 🔶 BIG LOGO
            Image.asset(
              "assets/welcome_logo.png",
              height: 180,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.person_add,
                  size: 100,
                  color: Color(0xFFD88A1F),
                );
              },
            ),
            const SizedBox(height: 8),

            const Text(
              "Create Customer Account",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              "Join biZEase as a customer",
              style: TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 22),

            _inputField(
              controller: usernameController,
              hint: "Enter your username",
              icon: Icons.person,
            ),
            _inputField(
              controller: emailController,
              hint: "Enter your email",
              icon: Icons.email,
            ),
            _inputField(
              controller: passwordController,
              hint: "Enter your password",
              icon: Icons.lock,
              isPassword: true,
              showToggle: true,
            ),

            const SizedBox(height: 24),

            /// 🔶 SIGN UP BUTTON
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD88A1F),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: _onSignup,
                child: const Text(
                  "SIGN UP",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            /// 🔶 ALREADY HAVE ACCOUNT
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Go back to login
              },
              child: const Text(
                "Already have an account? Login here",
                style: TextStyle(color: Color(0xFFD88A1F)),
              ),
            ),

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 10),

            const Text(
              "Or sign up with",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 15),

            /// 🔶 SOCIAL MEDIA ICONS
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _socialIcon(Icons.facebook, "https://www.facebook.com"),
                const SizedBox(width: 18),
                _socialIcon(Icons.g_mobiledata, "https://accounts.google.com"),
                const SizedBox(width: 18),
                _socialIcon(Icons.apple, "https://appleid.apple.com"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 🔶 INPUT FIELD
  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
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
          hintText: hint,
          prefixIcon: Icon(icon, color: const Color(0xFFD88A1F)),
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
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(color: Color(0xFFD88A1F)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(
              color: Color(0xFFD88A1F),
              width: 2,
            ),
          ),
        ),
      ),
    );
  }

  /// 🔶 SOCIAL ICON
  Widget _socialIcon(IconData icon, String url) {
    return InkWell(
      hoverColor: Colors.transparent,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      onTap: () async {
        // ignore: avoid_print
        print("Social icon tapped: $url");
        final Uri link = Uri.parse(url);
        if (await canLaunchUrl(link)) {
          await launchUrl(link, mode: LaunchMode.externalApplication);
        } else {
          _showError("Cannot launch $url");
        }
      },
      child: CircleAvatar(
        radius: 22,
        backgroundColor: const Color(0xFFD88A1F),
        child: Icon(
          icon,
          size: 28,
          color: Colors.white,
        ),
      ),
    );
  }
}