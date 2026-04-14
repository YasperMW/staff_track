import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import '../config/app_config.dart';

/// Response from Google auth API
class GoogleAuthResponse {
  final bool success;
  final bool exists;
  final String? message;
  final String? token;
  final Map<String, dynamic>? user;
  final Map<String, dynamic>? googleData;

  const GoogleAuthResponse({
    required this.success,
    this.exists = false,
    this.message,
    this.token,
    this.user,
    this.googleData,
  });
}

class GoogleAuthService {
  // Web client ID for backend token verification
  static const String _serverClientId =
      '152077619782-2kkf1h0rakope2d5l4pmnhbolkjv1mom.apps.googleusercontent.com';

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: _serverClientId,
    scopes: [
      'email',
      'profile',
    ],
  );

  /// Sign in with Google and get user data
  Future<GoogleSignInAccount?> signInWithGoogle() async {
    try {
      final account = await _googleSignIn.signIn();
      return account;
    } catch (e) {
      print('Google Sign-In error: $e');
      return null;
    }
  }

  /// Sign out from Google
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      print('Google Sign-Out error: $e');
    }
  }

  /// Get ID token from Google
  Future<String?> getIdToken() async {
    try {
      final account = _googleSignIn.currentUser;
      if (account == null) return null;

      final auth = await account.authentication;
      return auth.idToken;
    } catch (e) {
      print('Error getting ID token: $e');
      return null;
    }
  }

  /// Check if Google user exists in backend - login or get signup data
  Future<GoogleAuthResponse> checkGoogleUser(String idToken) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/auth/google'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id_token': idToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return GoogleAuthResponse(
          success: true,
          exists: data['exists'] as bool? ?? false,
          token: data['token'] as String?,
          user: data['user'] as Map<String, dynamic>?,
          googleData: data['google_data'] as Map<String, dynamic>?,
        );
      }

      final errorData = jsonDecode(response.body) as Map<String, dynamic>;
      return GoogleAuthResponse(
        success: false,
        message: errorData['detail']?.toString() ?? 'Authentication failed',
      );
    } catch (e) {
      return GoogleAuthResponse(
        success: false,
        message: 'Network error. Please check your connection.',
      );
    }
  }

  /// Complete Google user registration
  Future<GoogleAuthResponse> registerGoogleUser({
    required String idToken,
    required Map<String, dynamic> userData,
  }) async {
    try {
      // Combine id_token with user data
      final requestBody = {
        'id_token': idToken,
        ...userData,
      };

      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/auth/google/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return GoogleAuthResponse(
          success: true,
          exists: true,
          token: data['token'] as String?,
          user: data['user'] as Map<String, dynamic>?,
          message: data['message']?.toString(),
        );
      }

      final errorData = jsonDecode(response.body) as Map<String, dynamic>;
      return GoogleAuthResponse(
        success: false,
        message: errorData['detail']?.toString() ?? 'Registration failed',
      );
    } catch (e) {
      return GoogleAuthResponse(
        success: false,
        message: 'Network error. Please check your connection.',
      );
    }
  }
}