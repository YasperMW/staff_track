import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class OTPService {
  static Future<Map<String, dynamic>> sendOTP({
    required String email,
    String purpose = 'registration',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/auth/send-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'purpose': purpose,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          'success': data['success'] ?? false,
          'message': data['message'],
          'verified': data['verified'] ?? false,
        };
      }
      return {
        'success': false,
        'message': 'Failed to send OTP',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error. Please try again.',
      };
    }
  }

  static Future<Map<String, dynamic>> verifyOTP({
    required String email,
    required String otpCode,
    String purpose = 'registration',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/auth/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'otp_code': otpCode,
          'purpose': purpose,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          'success': data['success'] ?? false,
          'message': data['message'],
          'verified': data['verified'] ?? false,
        };
      }
      return {
        'success': false,
        'message': 'Invalid OTP',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error. Please try again.',
      };
    }
  }

  static Future<Map<String, dynamic>> resendOTP({
    required String email,
    String purpose = 'registration',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/auth/resend-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'purpose': purpose,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          'success': data['success'] ?? false,
          'message': data['message'],
          'verified': data['verified'] ?? false,
        };
      }
      return {
        'success': false,
        'message': 'Failed to resend OTP',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error. Please try again.',
      };
    }
  }
}
