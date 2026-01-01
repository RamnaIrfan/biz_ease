import 'package:flutter/material.dart';
import 'login_customer.dart';  // Make sure to import
import 'login_business.dart';  // Make sure to import

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7F7),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 64),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // LOGO
            Image.asset(
              "assets/welcome_logo.png",
              height: 320,
            ),

            const SizedBox(height: 1),

            // HELLO TEXT
            const Text(
              "HELLO!",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              "Please Select Your Role Below",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 30),

            // ✅ FIXED: CUSTOMER BUTTON
            _roleButton(
              text: "Customer",
              color: const Color(0xFFD88A1F),
              onTap: () {
                print("Customer button pressed");
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LoginCustomerPage(),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // ✅ FIXED: BUSINESS OWNER BUTTON
            _roleButton(
              text: "Business Owner",
              color: Colors.black,
              onTap: () {
                print("Business button pressed");
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LoginBusinessPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ROLE BUTTON WIDGET
  Widget _roleButton({
    required String text,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
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
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}