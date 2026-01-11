import 'package:biz_ease/screens/auth_provider.dart' show AuthProvider;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'home_page.dart';  // ✅ Import HomePage directly
import 'signup_customer.dart';  // ✅ Import SignupCustomerPage directly
import 'package:shared_preferences/shared_preferences.dart';

class LoginCustomerPage extends StatefulWidget {
  const LoginCustomerPage({super.key});

  @override
  State<LoginCustomerPage> createState() => _LoginCustomerPageState();
}

class _LoginCustomerPageState extends State<LoginCustomerPage> {
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
    final savedEmail = prefs.getString('saved_customer_email');
    if (savedEmail != null) {
      setState(() {
        usernameController.text = savedEmail;
      });
    }
  }

  Future<void> _saveEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_customer_email', email);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFD88A1F),
        title: const Text('Customer Login'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);  // Go back to welcome page
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              "assets/welcome_logo.png", 
              height: 220,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.person,
                  size: 100,
                  color: Color(0xFFD88A1F),
                );
              },
            ),
            const SizedBox(height: 10),

            const Text(
              "Please sign in as Customer",
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 10),

            _inputField(
              "Enter your username",
              controller: usernameController,
            ),

            _inputField(
              "Enter your password",
              controller: passwordController,
              isPassword: true,
              showToggle: true,
            ),

            const SizedBox(height: 15),

              // ✅ FIXED: Login Button - Use AuthProvider
              _actionButton("SIGN IN", () async {
                print("Login button pressed");
                
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
                    userType: "customer",
                  );
                  
                  // Save email for next time
                  await _saveEmail(email);
                  
                  // ✅ FIXED: Navigate to HomePage
                  if (context.mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HomePage(),
                      ),
                    );
                  }
                } catch (e) {
                  _showError(e.toString());
                }
              }),

            const SizedBox(height: 12),

            // ✅ FIXED: Sign Up Button - Use MaterialPageRoute
            TextButton(
              onPressed: () {
                print("Sign up button pressed");
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SignupCustomerPage(),
                  ),
                );
              },
              child: const Text(
                "Don't have account? Sign up here",
                style: TextStyle(color: Color(0xFFD88A1F)),
              ),
            ),
            
            // ✅ ADDED: Forgot Password option
            TextButton(
              onPressed: () {
                _showError("Forgot password feature coming soon!");
              },
              child: const Text(
                "Forgot Password?",
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🔔 ERROR MESSAGE
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// 🔶 INPUT FIELD
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

  /// 🔶 BUTTON
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
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}