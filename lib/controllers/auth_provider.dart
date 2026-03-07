import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/login_service.dart';
import '../services/auth_storage.dart';
import '../services/fcm_service.dart';

/// Result of a login attempt: either success with token and user, or failure with message.
class LoginResult {
  final bool success;
  final String? message;
  final String? token;
  final Map<String, dynamic>? user;

  const LoginResult({
    required this.success,
    this.message,
    this.token,
    this.user,
  });

  factory LoginResult.failure(String message) =>
      LoginResult(success: false, message: message);

  factory LoginResult.success({required String token, required Map<String, dynamic> user}) =>
      LoginResult(success: true, token: token, user: user);
}

/// Converts API user map to [AppUser].
AppUser appUserFromMap(Map<String, dynamic> map) {
  final first = map['first_name'] as String? ?? '';
  final surname = map['surname'] as String? ?? '';
  final name = [first, surname].where((s) => s.isNotEmpty).join(' ');
  return AppUser(
    id: map['user_id'] as String? ?? map['email'] as String? ?? '',
    name: name.isEmpty ? (map['email'] as String? ?? '') : name,
    email: map['email'] as String? ?? '',
    phone: map['phone'] as String? ?? map['phone_number'] as String? ?? '',
    role: map['role'] as String? ?? '',
    department: map['department'] as String? ?? '',
    profileImage: map['profile_photo_url'] as String? ?? '',
  );
}

class AuthProvider extends ChangeNotifier {
  final LoginService _loginService = LoginService();

  String? _token;
  AppUser? _user;
  bool _isLoading = true;

  String? get token => _token;
  AppUser? get user => _user;
  bool get isLoggedIn => _token != null && _token!.isNotEmpty;
  bool get isLoading => _isLoading;

  /// Load token and user from persistent storage. Call on app startup.
  Future<void> loadFromStorage() async {
    _isLoading = true;
    notifyListeners();
    try {
      _token = await AuthStorage.getToken();
      final userMap = await AuthStorage.getUser();
      if (userMap != null) {
        _user = appUserFromMap(userMap);
        // User is logged in, register FCM token
        FCMService.updateToken();
      } else {
        _user = null;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Optionally verify token with backend; if invalid, clear local auth.
  Future<void> verifyAndRestoreSession() async {
    _isLoading = true;
    notifyListeners();
    
    if (_token == null) {
      _isLoading = false;
      notifyListeners();
      return;
    }
    
    try {
      final valid = await _loginService.verifyToken(_token!);
      if (!valid) {
        await logout(skipApi: true);
      } else {
        // Token still valid, ensure FCM registration is up to date
        FCMService.updateToken();
      }
    } catch (e) {
      // On network error, we keep the session but might want to handle it
      debugPrint('Session verification failed: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Perform login; on success store token and user and notify.
  Future<LoginResult> login(String email, String password) async {
    final result = await _loginService.login(email: email, password: password);
    if (!result.success) {
      return LoginResult.failure(result.message ?? 'Invalid credentials');
    }
    if (result.token == null || result.user == null) {
      return LoginResult.failure('Invalid response from server');
    }
    _token = result.token;
    _user = appUserFromMap(result.user!);
    await AuthStorage.saveToken(result.token!);
    await AuthStorage.saveUser(result.user!);
    
    // Reset FCM cache and register for new user
    FCMService.clearTokenCache();
    FCMService.updateToken();
    
    notifyListeners();
    return LoginResult.success(token: result.token!, user: result.user!);
  }

  /// Clear auth and optionally call API logout.
  Future<void> logout({bool skipApi = false}) async {
    if (!skipApi && _token != null) {
      try {
        await _loginService.logout();
      } catch (_) {}
    }
    _token = null;
    _user = null;
    await AuthStorage.clear();
    
    // Clear FCM token cache so it can be re-registered for a different user
    FCMService.clearTokenCache();

    notifyListeners();
  }

  /// Update stored user (e.g. after profile update).
  Future<void> updateUser(Map<String, dynamic> userMap) async {
    _user = appUserFromMap(userMap);
    await AuthStorage.saveUser(userMap);
    notifyListeners();
  }

  /// Update just the profile photo locally.
  Future<void> updateProfilePhotoLocally(String photoUrl) async {
    if (_user != null) {
      _user = _user!.copyWith(profileImage: photoUrl);
      
      // Also update in storage
      final userMap = await AuthStorage.getUser();
      if (userMap != null) {
        userMap['profile_photo_url'] = photoUrl;
        await AuthStorage.saveUser(userMap);
      }
      
      notifyListeners();
    }
  }
}
