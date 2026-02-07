import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class StorageService {
  final String _cloudName = 'dn0svtleh';
  // Note: API Key is not strictly needed for unsigned uploads but kept for reference
  // final String _apiKey = '991361216152952'; 
  
  // TODO: Replace with your actual Unsigned Upload Preset from Cloudinary Dashboard -> Settings -> Upload -> Upload presets
  // If you haven't created one, go to Cloudinary Dashboard -> Settings -> Upload -> Add upload preset -> Signing Mode: Unsigned -> Name: biz_ease_upload (or whatever you like)
  final String _uploadPreset = 'images'; 

  /// Uploads a product image and returns the download URL.
  Future<String> uploadProductImage({String? path, Uint8List? bytes, required String fileName}) async {
    try {
      final Uri url = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload');
      final request = http.MultipartRequest('POST', url);

      request.fields['upload_preset'] = _uploadPreset;
      // request.fields['public_id'] = fileName.split('.').first; // Optional: unique public ID

      if (kIsWeb) {
        if (bytes == null) throw 'Web upload requires image bytes.';
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            bytes,
            filename: fileName,
          ),
        );
      } else {
        if (path == null) throw 'Mobile/Desktop upload requires a file path.';
        File file = File(path);
        if (!await file.exists()) throw 'File does not exist at path: $path';
        
        request.files.add(
          await http.MultipartFile.fromPath(
            'file',
            path,
          ),
        );
      }
      
      debugPrint('DEBUG: Starting upload to Cloudinary...');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final String downloadUrl = responseData['secure_url'];
        debugPrint('DEBUG: Upload successful! URL: $downloadUrl');
        return downloadUrl;
      } else {
        debugPrint('DEBUG: Cloudinary Error: ${response.reasonPhrase} - ${response.body}');
        
        // Try to parse error message
        String errorMessage = 'Unknown Cloudinary error';
        try {
           final errorJson = json.decode(response.body);
           if (errorJson['error'] != null) {
             errorMessage = errorJson['error']['message'];
           }
        } catch (_) {}

        throw 'Upload failed: $errorMessage';
      }

    } catch (e) {
      debugPrint('DEBUG: Storage Error: $e');
      throw 'Image upload failed: $e';
    }
  }
}
