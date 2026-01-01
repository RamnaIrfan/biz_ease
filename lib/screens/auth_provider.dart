// screens/auth_provider.dart
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_auth_service.dart';
import '../services/customer_service.dart';
import '../models/customer_model.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuthService _authService = FirebaseAuthService();
  final CustomerService _customerService = CustomerService();
  
  bool _isLoggedIn = false;
  String _username = '';
  String _email = '';
  String _userType = '';
  User? _firebaseUser;
  
  bool get isLoggedIn => _isLoggedIn;
  String get username => _username;
  String get email => _email;
  String get userType => _userType;
  User? get firebaseUser => _firebaseUser;
  
  AuthProvider() {
    // Listen to Firebase auth state changes
    _authService.authStateChanges.listen((User? user) {
      if (user != null) {
        _firebaseUser = user;
        _isLoggedIn = true;
        _email = user.email ?? '';
        _username = user.displayName ?? user.email?.split('@')[0] ?? 'User';
        
        // Try to get user type from Firestore or user metadata
        _loadUserType(user);
        
        notifyListeners();
      } else {
        _clearUserData();
        notifyListeners();
      }
    });
  }
  
  // Helper method to load user type
  Future<void> _loadUserType(User user) async {
    try {
      // Check if user is a customer in Firestore
      final customer = await _customerService.getCustomer(user.uid);
      if (customer != null) {
        _userType = 'customer';
      } else {
        // Check custom claims or other sources for user type
        // For now, default to 'customer' or you can implement your logic
        _userType = 'customer';
      }
    } catch (e) {
      print("Error loading user type: $e");
      _userType = 'customer'; // Default fallback
    }
  }
  
  // Helper method to clear user data
  void _clearUserData() {
    _firebaseUser = null;
    _isLoggedIn = false;
    _username = '';
    _email = '';
    _userType = '';
  }
  
  // Sign up with Firebase
  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String username,
    required String userType,
  }) async {
    try {
      UserCredential? credential = await _authService.signUpWithEmailPassword(
        email: email,
        password: password,
      );
      
      if (credential != null && credential.user != null) {
        _firebaseUser = credential.user;
        _isLoggedIn = true;
        _username = username;
        _email = email;
        _userType = userType;
        
        // Update display name in Firebase Auth
        try {
          await _authService.updateDisplayName(username);
        } catch (e) {
          print("Failed to update display name: $e");
          // Continue anyway
        }
        
        // Save customer data to Firestore (only for customers)
        try {
          if (userType == 'customer') {
            CustomerModel customer = CustomerModel(
              id: credential.user!.uid,
              username: username,
              email: email,
              createdAt: DateTime.now(),
            );
            await _customerService.createCustomer(customer);
          }
        } catch (firestoreError) {
          print("Firestore write failed (likely permissions): $firestoreError");
          // Don't rethrow - the user account was created successfully
          // The Firestore error is logged but doesn't prevent login
        }
        
        notifyListeners();
      }
    } catch (e) {
      rethrow;
    }
  }
  
  // Check if email already exists
  // Note: fetchSignInMethodsForEmail is deprecated/removed in newer Firebase versions
  // for security reasons (to prevent email enumeration).
  // It's better to handle "email already in use" errors during registration.
  Future<bool> checkEmailExists(String email) async {
    // This is no longer supported directly via fetchSignInMethodsForEmail in newer SDKs
    // unless you enable it in the Firebase Console.
    // For now, we return false and let the sign-up catch the error.
    return false;
  }
  
  // Sign in with Firebase
  Future<void> signInWithEmail({
    required String email,
    required String password,
    required String userType,
  }) async {
    try {
      UserCredential? credential = await _authService.signInWithEmailPassword(
        email: email,
        password: password,
      );
      
      if (credential != null && credential.user != null) {
        _firebaseUser = credential.user;
        _isLoggedIn = true;
        _email = email;
        _username = credential.user!.displayName ?? email.split('@')[0];
        _userType = userType;
        notifyListeners();
      }
    } catch (e) {
      rethrow;
    }
  }
  
  // Legacy methods for backward compatibility
  void loginCustomer(String username, String email) {
    _isLoggedIn = true;
    _username = username;
    _email = email;
    _userType = 'customer';
    notifyListeners();
    print("User logged in: $username, $email");
  }
  
  void loginBusiness(String username, String email) {
    _isLoggedIn = true;
    _username = username;
    _email = email;
    _userType = 'business';
    notifyListeners();
  }
  
  void updateProfile(String username, String email) {
    _username = username;
    _email = email;
    notifyListeners();
  }
  
  // Update Firebase user profile
  Future<void> updateFirebaseProfile(String username, String? email) async {
    try {
      if (_firebaseUser != null) {
        await _authService.updateDisplayName(username);
        if (email != null && email.isNotEmpty && email != _email) {
          await _firebaseUser!.verifyBeforeUpdateEmail(email);
        }
        
        _username = username;
        if (email != null && email.isNotEmpty) {
          _email = email;
        }
        notifyListeners();
      }
    } catch (e) {
      rethrow;
    }
  }
  
  // Sign out
  Future<void> logout() async {
    try {
      await _authService.signOut();
      _clearUserData();
      notifyListeners();
      print("User logged out");
    } catch (e) {
      print("Logout error: $e");
      rethrow;
    }
  }
  
  // Send password reset email
  Future<void> resetPassword(String email) async {
    try {
      await _authService.sendPasswordResetEmail(email);
    } catch (e) {
      rethrow;
    }
  }
  
  // Get current user ID
  String? get userId => _firebaseUser?.uid;
  
  // Check if user is authenticated
  bool get isAuthenticated => _firebaseUser != null;
}