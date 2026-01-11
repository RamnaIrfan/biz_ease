import 'package:flutter/material.dart';
import '../models/owner_model.dart';

import 'package:flutter/material.dart';
import '../models/owner_model.dart';
import 'business_settings_page.dart';

class OwnerProfilePage extends StatefulWidget {
  final OwnerModel owner;
  const OwnerProfilePage({super.key, required this.owner});

  @override
  State<OwnerProfilePage> createState() => _OwnerProfilePageState();
}

class _OwnerProfilePageState extends State<OwnerProfilePage> {
  late OwnerModel _currentOwner;
  static const orange = Color(0xFFD88A1F);

  @override
  void initState() {
    super.initState();
    _currentOwner = widget.owner;
  }

  void _showBusinessDetails() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Business Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow('Business Name', _currentOwner.businessName),
            _detailRow('Category', _currentOwner.category),
            _detailRow('Owner Name', _currentOwner.fullName),
            _detailRow('Phone', _currentOwner.phone),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showAddressBook() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Business Address', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: orange)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.location_on, color: orange),
              title: Text(_currentOwner.address),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          const Divider(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: orange,
        title: const Text("Profile Info business"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// PROFILE CARD
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: orange,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.white,
                    child: Text(
                      _currentOwner.fullName[0],
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: orange,
                          fontSize: 18),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_currentOwner.fullName,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                      Text(_currentOwner.businessName,
                          style: const TextStyle(color: Colors.white70)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            _section("ACCOUNT INFORMATION"),
            _tile(Icons.email, _currentOwner.email),
            _tile(Icons.phone, _currentOwner.phone),
            _tile(Icons.location_on, _currentOwner.address),

            const SizedBox(height: 14),

            _section("BUSINESS INFORMATION"),
            _nav("Address Book", onTap: _showAddressBook),
            _nav("Business Details", onTap: _showBusinessDetails),

            const SizedBox(height: 14),

            _section("SETTINGS"),
            _nav("Account Settings", onTap: () async {
              final updated = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => BusinessSettingsPage(owner: _currentOwner)),
              );
              if (updated != null && updated is OwnerModel) {
                setState(() => _currentOwner = updated);
              }
            }),

            const SizedBox(height: 30),

            ElevatedButton.icon(
              onPressed: () {
                Navigator.popUntil(context, (r) => r.isFirst);
              },
              icon: const Icon(Icons.logout),
              label: const Text("Logout"),
              style: ElevatedButton.styleFrom(
                backgroundColor: orange,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _section(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(text,
            style: const TextStyle(color: orange, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _tile(IconData icon, String text) {
    return ListTile(
      leading: Icon(icon, color: orange),
      title: Text(text),
    );
  }

  Widget _nav(String text, {VoidCallback? onTap}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        title: Text(text),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
