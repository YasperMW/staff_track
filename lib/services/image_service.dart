import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import '../config/app_config.dart';
import 'permission_service.dart';

class ImageService {
  final ImagePicker _picker = ImagePicker();

  Future<String?> pickImage() async {
    try {
      // Request camera permission
      bool hasPermission = await PermissionService.requestCameraPermission();
      if (!hasPermission) {
        if (kDebugMode) {
          print('Camera permission denied');
        }
        return null;
      }

      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (image != null) {
        return image.path;
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error picking image: $e');
      }
      return null;
    }
  }

  Future<String?> takePhoto() async {
    try {
      // Request camera permission
      bool hasPermission = await PermissionService.requestCameraPermission();
      if (!hasPermission) {
        if (kDebugMode) {
          print('Camera permission denied');
        }
        return null;
      }
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (photo != null) {
        return photo.path;
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error taking photo: $e');
      }
      return null;
    }
  }

  Future<String?> uploadImage(String imagePath) async {
    try {
      final File imageFile = File(imagePath);
      
      // Create multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConfig.apiBaseUrl}/files/upload/profile-photo'),
      );

      // Add image file with proper content type
      final imageBytes = await imageFile.readAsBytes();
      final fileName = imagePath.split('/').last;
      final fileExtension = fileName.split('.').last.toLowerCase();
      
      // Determine content type based on file extension
      String contentType = 'image/jpeg'; // default
      switch (fileExtension) {
        case 'png':
          contentType = 'image/png';
          break;
        case 'jpg':
        case 'jpeg':
          contentType = 'image/jpeg';
          break;
        case 'gif':
          contentType = 'image/gif';
          break;
        case 'webp':
          contentType = 'image/webp';
          break;
      }
      
      final imageFileUpload = http.MultipartFile.fromBytes(
        'file',
        imageBytes,
        filename: fileName,
        contentType: MediaType.parse(contentType),
      );
      
      request.files.add(imageFileUpload);

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          return responseData['file_url'];
        }
      }
      
      if (kDebugMode) {
        print('Upload failed with status: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
      
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error uploading image: $e');
      }
      return null;
    }
  }
}
