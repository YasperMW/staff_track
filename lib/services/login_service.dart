import '../utils/mock_data.dart';

class LoginService {
  Future<bool> login(String email, String password) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    
    // Use MockData for validation
    return MockData.login(email, password);
  }
}
