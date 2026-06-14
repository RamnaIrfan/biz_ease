
class OwnerModel {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String businessName;
  final String address;
  final String category;
  final bool emailAlertsEnabled;

  OwnerModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.businessName,
    required this.address,
    required this.category,
    this.emailAlertsEnabled = true,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'businessName': businessName,
      'address': address,
      'category': category,
      'emailAlertsEnabled': emailAlertsEnabled,
    };
  }

  // Create from Firestore document
  factory OwnerModel.fromMap(Map<String, dynamic> map, String documentId) {
    return OwnerModel(
      id: documentId,
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      businessName: map['businessName'] ?? '',
      address: map['address'] ?? '',
      category: map['category'] ?? '',
      emailAlertsEnabled: map['emailAlertsEnabled'] ?? true,
    );
  }
}
