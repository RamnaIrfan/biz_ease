// screens/settings_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/auth_provider.dart';
import '../services/product_service.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: const Color(0xFFD88A1F),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _settingsSection('Appearance', [
            _settingsItem(
              'Dark Mode',
              Icons.dark_mode,
              trailing: Switch(value: false, onChanged: (value) {}),
            ),
            _settingsItem(
              'Language',
              Icons.language,
              trailing: const Text('English'),
            ),
            _settingsItem(
              'Theme Color',
              Icons.palette,
              trailing: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: const Color(0xFFD88A1F),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ]),
          
          const SizedBox(height: 20),
          
          _settingsSection('Notifications', [
            _settingsItem(
              'Push Notifications',
              Icons.notifications,
              trailing: Switch(value: true, onChanged: (value) {}),
            ),
            _settingsItem(
              'Email Notifications',
              Icons.email,
              trailing: Switch(value: true, onChanged: (value) {}),
            ),
            _settingsItem(
              'Order Updates',
              Icons.shopping_bag,
              trailing: Switch(value: true, onChanged: (value) {}),
            ),
          ]),
          
          const SizedBox(height: 20),
          
          _settingsSection('Privacy & Security', [
            _settingsItem(
              'Change Password',
              Icons.lock,
              onTap: () {
                // Navigate to change password page
              },
            ),
            _settingsItem(
              'Privacy Policy',
              Icons.privacy_tip,
              onTap: () {
                // Navigate to privacy policy
              },
            ),
            _settingsItem(
              'Terms of Service',
              Icons.description,
              onTap: () {
                // Navigate to terms of service
              },
            ),
          ]),
          
          const SizedBox(height: 20),
          
          _settingsSection('Support', [
            _settingsItem(
              'Help Center',
              Icons.help,
              onTap: () {
                // Navigate to help center
              },
            ),
            _settingsItem(
              'Contact Us',
              Icons.contact_support,
              onTap: () {
                // Navigate to contact page
              },
            ),
            _settingsItem(
              'About App',
              Icons.info,
              onTap: () {
                // Navigate to about page
              },
            ),
          ]),

          const SizedBox(height: 20),

          // Maintenance Section (Only for Business Owners/Logged In users)
          _settingsSection('Maintenance', [
            _settingsItem(
              'Delete All Sample Products',
              Icons.delete_sweep,
              onTap: () async {
                final auth = Provider.of<AuthProvider>(context, listen: false);
                if (auth.userId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please login to use this feature')),
                  );
                  return;
                }

                // Confirm deletion
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Sample Products'),
                    content: const Text(
                      'This will delete all sample/dummy products from your inventory. This action cannot be undone. Continue?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Delete', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );

                if (confirmed != true || !context.mounted) return;

                // Show loading
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(child: CircularProgressIndicator()),
                );

                try {
                  final count = await ProductService().deleteAllSampleProducts(auth.userId!);
                  if (context.mounted) {
                    Navigator.pop(context); // Close loader
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Successfully deleted $count sample product${count == 1 ? '' : 's'}'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.pop(context); // Close loader
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
            ),
            _settingsItem(
              'Clean Duplicate Products',
              Icons.cleaning_services,
              onTap: () async {
                 // Trigger cleanup
                 final auth = Provider.of<AuthProvider>(context, listen: false);
                 if (auth.userId == null) {
                   ScaffoldMessenger.of(context).showSnackBar(
                     const SnackBar(content: Text('Please login to use this feature')),
                   );
                   return;
                 }

                showDialog(
                  context: context,
                  barrierDismissible: false, 
                  builder: (context) => const Center(child: CircularProgressIndicator()),
                );

                 try {
                   final count = await ProductService().cleanupDuplicates(auth.userId!);
                   if (context.mounted) {
                     Navigator. pop(context); // Close loader
                     ScaffoldMessenger.of(context).showSnackBar(
                       SnackBar(content: Text('Cleanup complete. Removed $count duplicates.')),
                     );
                   }
                 } catch (e) {
                   if (context.mounted) {
                     Navigator.pop(context); // Close loader
                     ScaffoldMessenger.of(context).showSnackBar(
                       SnackBar(content: Text('Error: $e')),
                     );
                   }
                 }
              },
            ),
            _settingsItem(
              'Delete Products by Name',
              Icons.delete_forever,
              onTap: () async {
                final auth = Provider.of<AuthProvider>(context, listen: false);
                if (auth.userId == null) return;

                final controller = TextEditingController();
                
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Products'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Enter exact product name to delete ALL copies:'),
                        TextField(
                          controller: controller,
                          decoration: const InputDecoration(
                            hintText: 'e.g., computer',
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () async {
                          final name = controller.text.trim();
                          if (name.isEmpty) return;
                          
                          Navigator.pop(context); // Close input dialog
                          
                          // Show loading
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => const Center(child: CircularProgressIndicator()),
                          );

                          try {
                            final count = await ProductService().deleteProductsByName(name, auth.userId!);
                            if (context.mounted) {
                              Navigator.pop(context); // Close loading
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Deleted $count products named "$name"')),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              Navigator.pop(context); // Close loading
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                          }
                        },
                        child: const Text('Delete All', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ]),
          
          const SizedBox(height: 30),
          
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