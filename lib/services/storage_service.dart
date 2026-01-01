import 'dart:io';
import 'dart:typed_data';
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

class StorageService {
  final String _folder = 'product_images';

  /// Uploads a product image and returns the download URL.
  Future<String> uploadProductImage({String? path, Uint8List? bytes, required String fileName}) async {
    try {
      if (Firebase.apps.isEmpty) {
        throw 'Firebase is not initialized. Please check main.dart.';
      }

      // Get instance directly to avoid late initialization issues
      final storageInstance = FirebaseStorage.instance;
      debugPrint('DEBUG: Using bucket: ${storageInstance.app.options.storageBucket}');
      
      // Use the root reference or child folder
      Reference ref = storageInstance.ref().child(_folder).child(fileName);
      UploadTask uploadTask;

      debugPrint('DEBUG: Starting upload for $fileName...');

      if (kIsWeb) {
        if (bytes == null) throw 'Web upload requires image bytes.';
        uploadTask = ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg')); 
      } else {
        if (path == null) throw 'Mobile/Desktop upload requires a file path.';
        File file = File(path);
        if (!await file.exists()) throw 'File does not exist at path: $path';
        uploadTask = ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
      }

      // Track progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        double progress = 100.0 * (snapshot.bytesTransferred / snapshot.totalBytes);
        debugPrint('DEBUG: Upload progress: $progress%');
      });

      // Wait for completion with a long timeout (2 mins)
      TaskSnapshot snapshot = await uploadTask.timeout(const Duration(minutes: 1));
      String url = await snapshot.ref.getDownloadURL();
      debugPrint('DEBUG: Upload successful! URL: $url');
      return url;
    } on FirebaseException catch (e) {
      debugPrint('DEBUG: Firebase Storage Exception: ${e.code} - ${e.message}');
      if (e.code == 'unauthorized') {
        throw 'Permission Denied: Please update your Firebase Storage Rules.';
      }
      throw 'Firebase Storage Error: ${e.message}';
    } catch (e) {
      debugPrint('DEBUG: Generic Storage Error: $e');
      if (e is TimeoutException) {
        throw 'Upload timed out. Is your internet connection or Firebase setup okay?';
      }
      throw 'Upload failed: $e';
    }
  }
}
