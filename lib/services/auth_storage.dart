import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

abstract class AuthStorage {
  static const _keyToken = 'auth_token';
  static const _keyUser = 'auth_user';

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_keyToken);
    print('AuthStorage: Token ${token == null ? 'not found' : 'found (${token.length} chars)'}');
    return token;
  }

  static Future<void> saveUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUser, jsonEncode(user));
  }

  static Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyUser);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static Future<String?> getUserId() async {
    final user = await getUser();
    if (user == null) {
      print('AuthStorage: No user data found');
      return null;
    }
    
    print('AuthStorage: User data keys: ${user.keys.toList()}');
    print('AuthStorage: Full user data: $user');
    
    // Try different possible ID field names
    final id = user['user_id'] ?? user['id'] ?? user['userId'];
    
    if (id != null) {
      final idString = id.toString();
      print('AuthStorage: Found user ID: $idString');
      return idString;
    }
    
    // Fallback to email if no ID field is found
    final email = user['email'];
    if (email != null) {
      print('AuthStorage: Using email as user ID fallback: $email');
      return email.toString();
    }
    
    print('AuthStorage: No user ID or email found in user data');
    return null;
  }

  static Future<bool> isAuthenticated() async {
    final token = await getToken();
    final userId = await getUserId();
    final isAuth = token != null && userId != null;
    print('AuthStorage: Authentication status: $isAuth (token: ${token != null}, userId: ${userId != null})');
    return isAuth;
  }

  static Future<bool> refreshUserData() async {
    try {
      final token = await getToken();
      if (token == null) {
        print('AuthStorage: Cannot refresh user data - no token');
        return false;
      }
      
      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/users/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body) as Map<String, dynamic>;
        await saveUser(userData);
        print('AuthStorage: User data refreshed successfully');
        return true;
      } else {
        print('AuthStorage: Failed to refresh user data: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('AuthStorage: Error refreshing user data: $e');
      return false;
    }
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUser);
  }
}
