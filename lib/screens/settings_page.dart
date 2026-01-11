// screens/settings_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/auth_provider.dart';
import '../services/firebase_auth_service.dart';
import 'theme_provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final orangeColor = const Color(0xFFD88A1F);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: orangeColor,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _settingsSection('Appearance', [
            _settingsItem(
              'Dark Mode',
              Icons.dark_mode,
              trailing: Switch(
                value: themeProvider.isDarkMode,
                onChanged: (value) => themeProvider.toggleTheme(value),
              ),
            ),
            _settingsItem(
              'Language',
              Icons.language,
              trailing: const Text('English'),
            ),
          ]),
          
          const SizedBox(height: 20),
          
          _settingsSection('Privacy & Security', [
            _settingsItem(
              'Change Password',
              Icons.lock,
              onTap: () async {
                final auth = Provider.of<AuthProvider>(context, listen: false);
                if (auth.email != null) {
                  try {
                    await FirebaseAuthService().sendPasswordResetEmail(auth.email!);
                    if (context.mounted) {
                      _showInfoDialog(context, 'Reset Email Sent', 'A password reset link has been sent to ${auth.email}. Please check your inbox.');
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please login to change password')));
                }
              },
            ),
            _settingsItem(
              'Privacy Policy',
              Icons.privacy_tip,
              onTap: () {
                _showInfoDialog(context, 'Privacy Policy', 'At biZEase, we value your privacy. We collect only the data necessary to provide our services, such as your email for account management and address for order delivery. Your data is stored securely in Firebase and is never sold to third parties. For more details, contact our support team.');
              },
            ),
            _settingsItem(
              'Terms of Service',
              Icons.description,
              onTap: () {
                _showInfoDialog(context, 'Terms of Service', 'By using biZEase, you agree to our terms. Our platform facilitates transactions between buyers and local business owners. While we ensure service security, we are not responsible for direct quality issues from independent sellers. Users must provide accurate information for reliable order fulfillment.');
              },
            ),
          ]),
          
          const SizedBox(height: 20),
          
          _settingsSection('Support', [
            _settingsItem(
              'Help Center',
              Icons.help,
              onTap: () {
                _showInfoDialog(context, 'Help Center', 'Need help? Check out our FAQs on how to place orders, track your delivery, or contact sellers. If you encounter technical issues, please reach out to our support team via "Contact Us".');
              },
            ),
            _settingsItem(
              'Contact Us',
              Icons.contact_support,
              onTap: () {
                _showInfoDialog(context, 'Contact Us', 'You can reach biZEase support through the following channels:\n\n📧 Email: support@bizease.com\n📞 Phone: +92 300 1234567\n📍 Office: Sector H-12, Islamabad');
              },
            ),
            _settingsItem(
              'About App',
              Icons.info,
              onTap: () {
                _showInfoDialog(context, 'About App', 'biZEase is a modern platform designed to empower local businesses and simplify shopping for customers. Built using Flutter and Firebase, our mission is to make business development easy and accessible for everyone.');
              },
            ),
          ]),

          Center(
            child: Text(
              'Version 1.0.0',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFD88A1F))),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Color(0xFFD88A1F))),
          ),
        ],
      ),
    );
  }

  Widget _settingsSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: items,
          ),
        ),
      ],
    );
  }

  Widget _settingsItem(String title, IconData icon, {
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFFD88A1F)),
      title: Text(title),
      trailing: trailing,
      onTap: onTap,
    );
  }
}