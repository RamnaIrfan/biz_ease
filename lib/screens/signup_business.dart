import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/auth_provider.dart';
import '../utils/auth_state.dart';

class SignupBusinessPage extends StatefulWidget {
  const SignupBusinessPage({super.key});

  @override
  State<SignupBusinessPage> createState() => _SignupBusinessPageState();
}

class _SignupBusinessPageState extends State<SignupBusinessPage> {
  final TextEditingController businessController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // 🔒 PASSWORD VISIBILITY (NEVER NULL)
  bool _obscurePassword = true;

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
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
            const Text('Welcome to BizEase! Your business account is ready:'),
            const SizedBox(height: 16),
            Text('Business: $username', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('Email: $email', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text('Proceed to finish your business registration.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/registerBusiness');
            },
            child: const Text('Proceed'),
          ),
        ],
      ),
    );
  }

// In SignupBusinessPage - Update the SIGN UP button:
void _onSignup() async {
  if (businessController.text.isEmpty) {
    _showError("Please enter business name");
    return;
  }
  if (emailController.text.isEmpty) {
    _showError("Please enter email");
    return;
  }
  if (!emailController.text.contains('@gmail.com')) {
    _showError("Email must be a valid @gmail.com address");
    return;
  }
  if (passwordController.text.isEmpty) {
    _showError("Please enter password");
    return;
  }
  if (passwordController.text.length < 6) {
    _showError("Password must be at least 6 characters");
    return;
  }
  if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(passwordController.text)) {
    _showError("Password must contain 1 special character");
    return;
  }
  final authProvider = Provider.of<AuthProvider>(context, listen: false);

  try {
    await authProvider.signUpWithEmail(
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
      username: businessController.text.trim(),
      userType: 'business',
    );

    // ✅ Update legacy AuthState for compatibility
    AuthState.isLoggedIn = true;
    AuthState.userType = 'business';

    _showConfirmationDialog(businessController.text.trim(), emailController.text.trim());

    Future.delayed(const Duration(milliseconds: 3000), () {
      if (context.mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
        Navigator.pushReplacementNamed(context, '/registerBusiness');
      }
    });
  } catch (e) {
    debugPrint('Business signup error: $e');
    if (mounted) {
      _showError(e.toString());
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 60),

              // 🔶 BIG LOGO
              Image.asset(
                "assets/welcome_logo.png",
                height: 220,
              ),

              const SizedBox(height: 8),

              const Text(
                "Create Business Account",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 6),

              const Text(
                "Register your business with BizEase",
                style: TextStyle(color: Colors.grey),
              ),

              const SizedBox(height: 22),

              _inputField(
                controller: businessController,
                hint: "Enter your business name",
                icon: Icons.store,
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
              ),

              const SizedBox(height: 24),

              // 🔶 SIGN UP BUTTON
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
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // 🔶 SOCIAL ICONS
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

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // 🔶 INPUT FIELD WITH EYE ICON
  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        obscureText: isPassword && _obscurePassword,
        cursorColor: const Color(0xFFD88A1F),
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: const Color(0xFFD88A1F)),
          suffixIcon: isPassword
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
            borderSide:
                const BorderSide(color: Color(0xFFD88A1F), width: 2),
          ),
        ),
      ),
    );
  }

  // 🔶 SOCIAL ICON
  Widget _socialIcon(IconData icon, String url) {
    return InkWell(
      onTap: () async {
        // final Uri link = Uri.parse(url);
        // if (await canLaunchUrl(link)) {
        //   await launchUrl(link, mode: LaunchMode.externalApplication);
        // }
      },
      child: CircleAvatar(
        radius: 22,
        backgroundColor: const Color(0xFFD88A1F),
        child: Icon(icon, size: 28, color: Colors.white),
      ),
    );
  }
}