import '../utils/mock_data.dart';

class RegisterService {
  Future<bool> register({
    required String employeeNumber,
    required String nationalId,
    required String fullName,
    required String email,
    required String phone,
    required String role,
    required String department,
    required String password,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));
    
    // In a real app, you would call an API here
    // For now, we just simulate success
    return true;
  }

  List<String> getRoles() {
    return MockData.roles;
  }

  List<String> getDepartments() {
    return MockData.departments;
  }
}
