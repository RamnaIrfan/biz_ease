import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../utils/auth_state.dart';
import '../models/owner_model.dart';
import '../services/owner_service.dart';
import '../screens/auth_provider.dart';
import 'owner_dashboard_page.dart';

class RegisterBusinessPage extends StatefulWidget {
  const RegisterBusinessPage({super.key});

  @override
  State<RegisterBusinessPage> createState() => _RegisterBusinessPageState();
}

class _RegisterBusinessPageState extends State<RegisterBusinessPage> {
  static const orange = Color(0xFFD88A1F);

  final _fullName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _businessName = TextEditingController();
  final _description = TextEditingController();
  final _address = TextEditingController();
  final _policy = TextEditingController();

  String? selectedCategory;
  String? selectedFileName;
  TimeOfDay? openTime;
  TimeOfDay? closeTime;
  String? selectedCountry;


  final Map<String, bool> paymentMethods = {
    "Cash on Delivery": false,
    "Credit / Debit Card": false,
    "JazzCash": false,
    "EasyPaisa": false,
    "Bank Transfer": false,
  };

  final List<String> categories = [
    "Restaurant",
    "Grocery Store",
    "Clothing",
    "Electronics",
    "Pharmacy",
    "Beauty Salon",
    "Hardware Store",
    "Book Store",
    "Mobile Shop",
    "Other",
  ];

  final List<String> countries = [
  "Pakistan",
  "India",
  "USA",
  "UK",
  "UAE",
  "Saudi Arabia",
  "Canada",
  "Australia",
];


  void _showError(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() => selectedFileName = result.files.single.name);
    }
  }

  Future<void> _pickTime(bool isOpen) async {
    final picked =
        await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked != null) {
      setState(() => isOpen ? openTime = picked : closeTime = picked);
    }
  }


  void _completeRegistration() {
    if (_fullName.text.isEmpty) return _showError("Enter Full Name");
    if (!_email.text.contains("@gmail.com")) {
      return _showError("Email must contain @gmail.com");
    }
    if (!RegExp(r'^\+\d{1,4}\d{7,14}$').hasMatch(_phone.text)) {
  return _showError("Enter phone with country code (e.g. +923001234567)");
}
if (selectedCountry == null) {
  return _showError("Select country");
}

    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(_password.text)) {
      return _showError("Password must contain special character");
    }
    if (_businessName.text.isEmpty) {
      return _showError("Enter Business Name");
    }
    if (selectedCategory == null) {
      return _showError("Select Business Category");
    }
    if (_description.text.isEmpty) {
      return _showError("Describe your business");
    }
    if (_address.text.isEmpty) {
      return _showError("Enter Business Address");
    }
    if (selectedFileName == null) {
      return _showError("Upload business logo");
    }
    if (!paymentMethods.containsValue(true)) {
      return _showError("Select at least one payment method");
    }
    if (openTime == null || closeTime == null) {
      return _showError("Select opening & closing time");
    }
    if (_policy.text.isEmpty) {
      return _showError("Enter return/exchange policy");
    }
    

    /// ✅ CREATE MODEL
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.userId;

    if (userId == null) {
      return _showError("You must be signed in to register a business.");
    }

    final owner = OwnerModel(
      id: userId,
      fullName: _fullName.text,
      email: _email.text,
      phone: _phone.text,
      businessName: _businessName.text,
      address: _address.text,
      category: selectedCategory!,
    );

    // ✅ SAVE TO FIRESTORE
    final ownerService = OwnerService();
    ownerService.createOwner(owner).then((_) {
      AuthState.isBusinessRegistered = true;
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => OwnerDashboardPage(owner: owner),
          ),
        );
      }
    }).catchError((e) {
      if (mounted) {
        _showError(e.toString());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  decoration: BoxDecoration(
                    color: orange,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Text(
                    "Register Your Business",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              _title("Personal Details"),
              _input("Full Name", Icons.person, _fullName),
              _input("Email", Icons.email, _email),
              _input("Phone Number", Icons.phone, _phone),
              _input("Password", Icons.lock, _password, isPassword: true),

              _title("Business Information"),
              _input("Business Name", Icons.store, _businessName),


DropdownButtonFormField<String>(
  
  decoration: _inputDecoration("Select Country", Icons.public),
  
  items: countries
      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
      .toList(),
  onChanged: (v) => setState(() => selectedCountry = v),
),
DropdownButtonFormField<String>(
  decoration: _inputDecoration("Select Category", Icons.category),
  initialValue: selectedCategory,
  items: categories
      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
      .toList(),
  onChanged: (v) => setState(() => selectedCategory = v),
),

              const SizedBox(height: 12),
              _input("Business Description", Icons.description, _description),
              _input("Business Address", Icons.location_on, _address),

              _title("Business Logo"),
              ElevatedButton.icon(
                onPressed: _pickFile,
                icon: const Icon(Icons.upload),
                label: const Text("Choose File"),
                style: ElevatedButton.styleFrom(backgroundColor: orange),
              ),
              Text(selectedFileName ?? "No file selected"),

              _title("Payment Methods"),
              ...paymentMethods.keys.map(
                (m) => CheckboxListTile(
                  activeColor: orange,
                  title: Text(m),
                  value: paymentMethods[m],
                  onChanged: (v) =>
                      setState(() => paymentMethods[m] = v!),
                ),
              ),

              _title("Operating Hours"),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _pickTime(true),
                      child: Text(
                        openTime == null
                            ? "Opening Time"
                            : openTime!.format(context),
                        style: const TextStyle(color: orange),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _pickTime(false),
                      child: Text(
                        closeTime == null
                            ? "Closing Time"
                            : closeTime!.format(context),
                        style: const TextStyle(color: orange),
                      ),
                    ),
                  ),
                ],
              ),

              _input("Return / Exchange Policy", Icons.policy, _policy),

              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: orange,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                  onPressed: _completeRegistration,
                  child: const Text(
                    "Complete Registration",
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _title(String t) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 8),
        child: Text(
          t,
          style: const TextStyle(
              color: orange, fontWeight: FontWeight.bold),
        ),
      );

  Widget _input(String hint, IconData icon,
      TextEditingController controller,
      {bool isPassword = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        decoration: _inputDecoration(hint, icon),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: orange),
      filled: true,
      fillColor: Colors.white,
      hoverColor: const Color(0xFFFFE2BD),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: orange),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: orange, width: 2),
      ),
    );
  }
}
