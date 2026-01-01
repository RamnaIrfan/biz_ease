import 'package:flutter/material.dart';
import '../models/owner_model.dart';

class OwnerProfilePage extends StatelessWidget {
  final OwnerModel owner;
  const OwnerProfilePage({super.key, required this.owner});
 


  static const orange = Color(0xFFD88A1F);

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
                      owner.fullName[0],
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
                      Text(owner.fullName,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                      Text(owner.businessName,
                          style: const TextStyle(color: Colors.white70)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            _section("ACCOUNT INFORMATION"),
            _tile(Icons.email, owner.email),
            _tile(Icons.phone, owner.phone),
            _tile(Icons.location_on, owner.address),

            const SizedBox(height: 14),

            _section("BUSINESS INFORMATION"),
            _nav("Address Book"),
            _nav("Business Details"),

            const SizedBox(height: 14),

            _section("SETTINGS"),
            _nav("Account Settings"),
            _nav("Address Book"),
            _nav("Business Details"),

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
      child: Text(text,
          style:
              const TextStyle(color: orange, fontWeight: FontWeight.bold)),
    );
  }

  Widget _tile(IconData icon, String text) {
    return ListTile(
      leading: Icon(icon, color: orange),
      title: Text(text),
    );
  }

  Widget _nav(String text) {
    return ListTile(
      title: Text(text),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
    );
  }
}
