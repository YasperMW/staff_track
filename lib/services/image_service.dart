import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import '../config/app_config.dart';
import 'permission_service.dart';

/// Custom exception for image-related errors
class ImageException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const ImageException(this.message, {this.code, this.originalError});

  @override
  String toString() => message;
}

/// Result of an image pick operation
class ImagePickResult {
  final String? path;
  final String? error;
  final String? code;
  final bool cancelled;

  const ImagePickResult({this.path, this.error, this.code, this.cancelled = false});

  bool get isSuccess => path != null;
}

/// Configuration for image compression and quality
class ImageConfig {
  final int maxWidth;
  final int maxHeight;
  final int imageQuality;

  const ImageConfig({
    this.maxWidth = 800,
    this.maxHeight = 800,
    this.imageQuality = 85,
  });

  // Getters that return double for use with image_picker
  double get maxWidthDouble => maxWidth.toDouble();
  double get maxHeightDouble => maxHeight.toDouble();

  static const ImageConfig defaultConfig = ImageConfig();
  static const ImageConfig highQuality = ImageConfig(
    maxWidth: 1200,
    maxHeight: 1200,
    imageQuality: 90,
  );
  static const ImageConfig thumbnail = ImageConfig(
    maxWidth: 200,
    maxHeight: 200,
    imageQuality: 70,
  );
}

class ImageService {
  final ImagePicker _picker = ImagePicker();

  /// Pick an image from gallery with enhanced error handling
  Future<ImagePickResult> pickFromGallery({ImageConfig config = ImageConfig.defaultConfig}) async {
    try {
      final hasPermission = await PermissionService.requestCameraPermission();
      if (!hasPermission) {
        return const ImagePickResult(
          error: 'Permission denied. Please allow access to gallery.',
          code: 'PERMISSION_DENIED',
        );
      }

      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: config.maxWidthDouble,
        maxHeight: config.maxHeightDouble,
        imageQuality: config.imageQuality,
      );

      if (image == null) {
        return const ImagePickResult(cancelled: true);
      }

      // Validate file exists and has content
      final file = File(image.path);
      if (!await file.exists()) {
        return const ImagePickResult(
          error: 'Selected file does not exist',
          code: 'FILE_NOT_FOUND',
        );
      }

      final fileSize = await file.length();
      if (fileSize == 0) {
        return const ImagePickResult(
          error: 'Selected file is empty',
          code: 'EMPTY_FILE',
        );
      }

      // Check file size (max 10MB)
      if (fileSize > 10 * 1024 * 1024) {
        return const ImagePickResult(
          error: 'Image size must be less than 10MB',
          code: 'FILE_TOO_LARGE',
        );
      }

      return ImagePickResult(path: image.path);
    } catch (e) {
      if (kDebugMode) {
        print('Error picking image from gallery: $e');
      }
      return ImagePickResult(
        error: 'Failed to pick image: ${_getErrorMessage(e)}',
        code: 'PICK_ERROR',
      );
    }
  }

  /// Capture a photo with camera with enhanced error handling
  Future<ImagePickResult> capturePhoto({ImageConfig config = ImageConfig.defaultConfig}) async {
    try {
      final hasPermission = await PermissionService.requestCameraPermission();
      if (!hasPermission) {
        return const ImagePickResult(
          error: 'Permission denied. Please allow camera access.',
          code: 'PERMISSION_DENIED',
        );
      }

      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: config.maxWidthDouble,
        maxHeight: config.maxHeightDouble,
        imageQuality: config.imageQuality,
      );

      if (photo == null) {
        return const ImagePickResult(cancelled: true);
      }

      // Validate file
      final file = File(photo.path);
      if (!await file.exists()) {
        return const ImagePickResult(
          error: 'Photo file does not exist',
          code: 'FILE_NOT_FOUND',
        );
      }

      return ImagePickResult(path: photo.path);
    } catch (e) {
      if (kDebugMode) {
        print('Error taking photo: $e');
      }
      return ImagePickResult(
        error: 'Failed to take photo: ${_getErrorMessage(e)}',
        code: 'CAMERA_ERROR',
      );
    }
  }

  /// Upload image with retry logic and better error handling
  Future<String?> uploadImage(String imagePath, {int maxRetries = 2}) async {
    int attempt = 0;

    while (attempt <= maxRetries) {
      try {
        final result = await _uploadImageOnce(imagePath);
        if (result != null) {
          return result;
        }

        // If upload returned null but didn't throw, retry
        attempt++;
        if (attempt <= maxRetries) {
          if (kDebugMode) {
            print('Upload attempt $attempt failed, retrying...');
          }
          await Future.delayed(Duration(seconds: attempt));
        }
      } on ImageException catch (e) {
        // Don't retry on validation errors
        if (e.code == 'VALIDATION_ERROR') {
          rethrow;
        }
        attempt++;
        if (attempt > maxRetries) {
          rethrow;
        }
        await Future.delayed(Duration(seconds: attempt));
      } catch (e) {
        attempt++;
        if (attempt > maxRetries) {
          throw ImageException('Failed to upload image after $maxRetries attempts', originalError: e);
        }
        await Future.delayed(Duration(seconds: attempt));
      }
    }

    return null;
  }

  Future<String?> _uploadImageOnce(String imagePath) async {
    try {
      final File imageFile = File(imagePath);

      // Validate file exists
      if (!await imageFile.exists()) {
        throw const ImageException('Image file does not exist', code: 'FILE_NOT_FOUND');
      }

      // Validate file size (max 10MB)
      final fileSize = await imageFile.length();
      if (fileSize > 10 * 1024 * 1024) {
        throw const ImageException('Image size must be less than 10MB', code: 'FILE_TOO_LARGE');
      }

      // Validate file extension
      final fileName = imagePath.split(Platform.pathSeparator).last;
      final fileExtension = fileName.split('.').last.toLowerCase();
      final allowedExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'heic', 'heif'];

      if (!allowedExtensions.contains(fileExtension)) {
        throw ImageException(
          'Unsupported file format. Please use: ${allowedExtensions.join(', ')}',
          code: 'INVALID_FORMAT',
        );
      }

      // Determine content type
      final contentType = _getContentType(fileExtension);

      // Create multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConfig.apiBaseUrl}/files/upload/profile-photo'),
      );

      // Read and add image file
      final imageBytes = await imageFile.readAsBytes();
      final imageFileUpload = http.MultipartFile.fromBytes(
        'file',
        imageBytes,
        filename: 'profile_photo.$fileExtension',
        contentType: MediaType.parse(contentType),
      );

      request.files.add(imageFileUpload);

      // Send request with timeout
      final streamedResponse = await request.send().timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          return responseData['file_url'];
        }
        // Handle API-level errors
        final errorMessage = responseData['message'] ?? responseData['error'] ?? 'Upload failed';
        throw ImageException(errorMessage, code: 'API_ERROR');
      }

      // Handle HTTP errors
      String errorMessage = 'Upload failed';
      switch (response.statusCode) {
        case 400:
          errorMessage = 'Invalid request. Please check your image.';
          break;
        case 401:
          errorMessage = 'Session expired. Please log in again.';
          break;
        case 413:
          errorMessage = 'Image is too large. Please select a smaller image.';
          break;
        case 429:
          errorMessage = 'Too many requests. Please try again later.';
          break;
        case 500:
        case 502:
        case 503:
          errorMessage = 'Server error. Please try again later.';
          break;
      }

      if (kDebugMode) {
        print('Upload failed with status: ${response.statusCode}');
        print('Response body: ${response.body}');
      }

      throw ImageException(errorMessage, code: 'HTTP_${response.statusCode}');
    } on ImageException {
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        print('Error uploading image: $e');
      }
      throw ImageException('Network error. Please check your connection.', originalError: e);
    }
  }

  /// Get content type from file extension
  String _getContentType(String extension) {
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'heic':
      case 'heif':
        return 'image/heic';
      case 'jpg':
      case 'jpeg':
      default:
        return 'image/jpeg';
    }
  }

  /// Extract user-friendly error message from exception
  String _getErrorMessage(dynamic error) {
    if (error is ImageException) {
      return error.message;
    }
    if (error is Exception) {
      return error.toString().replaceFirst('Exception: ', '');
    }
    return error.toString();
  }

  /// Legacy methods for backward compatibility
  @Deprecated('Use pickFromGallery instead')
  Future<String?> pickImage() async {
    final result = await pickFromGallery();
    return result.path;
  }

  /// Take a photo - legacy method for backward compatibility
  @Deprecated('Use capturePhoto() instead for more detailed results')
  Future<String?> takePhoto() async {
    final result = await capturePhoto();
    return result.path;
  }
}
