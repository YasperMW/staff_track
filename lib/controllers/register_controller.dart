
import '../services/register_service.dart';

class RegisterController {
  final RegisterService _registerService = RegisterService();

  // Form data state
  String employeeNumber = '';
  String nationalId = '';
  String suffix = '';
  String firstName = '';
  String surName = '';
  String otherNames = '';
  String dateOfBirth = '';
  String gender = '';
  String email = '';
  String phone = '';
  String homeOfOrigin = '';
  String traditionalAuthority = '';
  String district = '';
  String currentAddress = '';
  String maritalStatus = '';
  String spouseName = '';
  String spouseContact = '';
  String dateOfEmployment = '';
  String designationId = '';
  String role = '';
  String department = '';
  bool isHeadOfDepartment = false;
  String password = '';

  // Validation methods
  String? validateEmployeeNumber(String? value) {
    if (value == null || value.isEmpty) return 'Employee number is required';
    if (value.length < 3) return 'Employee number too short';
    return null;
  }

  String? validateNationalId(String? value) {
    if (value == null || value.isEmpty) return 'National ID is required';
    if (value.length < 6) return 'National ID too short';
    return null;
  }

  String? validateName(String? value, String fieldName) {
    if (value == null || value.isEmpty) return '$fieldName is required';
    if (value.length < 2) return '$fieldName too short';
    return null;
  }

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Email is required';
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? validatePhone(String? value) {
    if (value == null || value.isEmpty) return 'Phone number is required';
    if (!RegExp(r'^\+?[\d\s\-\(\)]+$').hasMatch(value)) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  String? validateDropdown(String? value, String fieldName) {
    if (value == null || value.isEmpty) return 'Please select $fieldName';
    return null;
  }

  // Update methods for form data
  void updateEmployeeNumber(String value) => employeeNumber = value;
  void updateNationalId(String value) => nationalId = value;
  void updateSuffix(String value) => suffix = value;
  void updateFirstName(String value) => firstName = value;
  void updateSurName(String value) => surName = value;
  void updateOtherNames(String value) => otherNames = value;
  void updateDateOfBirth(String value) => dateOfBirth = value;
  void updateGender(String value) => gender = value;
  void updateEmail(String value) => email = value;
  void updatePhone(String value) => phone = value;
  void updateHomeOfOrigin(String value) => homeOfOrigin = value;
  void updateTraditionalAuthority(String value) => traditionalAuthority = value;
  void updateDistrict(String value) => district = value;
  void updateCurrentAddress(String value) => currentAddress = value;
  void updateMaritalStatus(String value) => maritalStatus = value;
  void updateSpouseName(String value) => spouseName = value;
  void updateSpouseContact(String value) => spouseContact = value;
  void updateDateOfEmployment(String value) => dateOfEmployment = value;
  void updateDesignationId(String value) => designationId = value;
  void updateRole(String value) => role = value;
  void updateDepartment(String value) => department = value;
  void updateIsHeadOfDepartment(bool value) => isHeadOfDepartment = value;
  void updatePassword(String value) => password = value;

  // Registration method
  Future<RegisterResponse> register() async {
    // Validate all required fields and return first error message
    final employeeError = validateEmployeeNumber(employeeNumber);
    if (employeeError != null) {
      return RegisterResponse(success: false, message: employeeError);
    }

    final nationalIdError = validateNationalId(nationalId);
    if (nationalIdError != null) {
      return RegisterResponse(success: false, message: nationalIdError);
    }

    final firstNameError = validateName(firstName, 'First Name');
    if (firstNameError != null) {
      return RegisterResponse(success: false, message: firstNameError);
    }

    final surNameError = validateName(surName, 'Surname');
    if (surNameError != null) {
      return RegisterResponse(success: false, message: surNameError);
    }

    final emailError = validateEmail(email);
    if (emailError != null) {
      return RegisterResponse(success: false, message: emailError);
    }

    final phoneError = validatePhone(phone);
    if (phoneError != null) {
      return RegisterResponse(success: false, message: phoneError);
    }

    final homeError = validateHomeOfOrigin();
    if (homeError != null) {
      return RegisterResponse(success: false, message: homeError);
    }

    final districtError = validateDistrict();
    if (districtError != null) {
      return RegisterResponse(success: false, message: districtError);
    }

    final addressError = validateCurrentAddress();
    if (addressError != null) {
      return RegisterResponse(success: false, message: addressError);
    }

    final maritalStatusError = validateDropdown(maritalStatus, 'Marital Status');
    if (maritalStatusError != null) {
      return RegisterResponse(success: false, message: maritalStatusError);
    }

    final employmentDateError = validateDateOfEmployment();
    if (employmentDateError != null) {
      return RegisterResponse(success: false, message: employmentDateError);
    }

    final designationError = validateDesignation(designationId);
    if (designationError != null) {
      return RegisterResponse(success: false, message: designationError);
    }

    final roleError = validateDropdown(role, 'Role');
    if (roleError != null) {
      return RegisterResponse(success: false, message: roleError);
    }

    final departmentError = validateDropdown(department, 'Department');
    if (departmentError != null) {
      return RegisterResponse(success: false, message: departmentError);
    }

    final passwordError = validatePassword(password);
    if (passwordError != null) {
      return RegisterResponse(success: false, message: passwordError);
    }

    return await _registerService.register(
      employeeNumber: employeeNumber,
      nationalId: nationalId,
      suffix: suffix,
      firstName: firstName,
      surName: surName,
      otherNames: otherNames,
      dateOfBirth: dateOfBirth,
      gender: gender,
      email: email,
      phone: phone,
      homeOfOrigin: homeOfOrigin,
      traditionalAuthority: traditionalAuthority,
      district: district,
      currentAddress: currentAddress,
      maritalStatus: maritalStatus,
      spouseName: spouseName,
      spouseContact: spouseContact,
      dateOfEmployment: dateOfEmployment,
      
      designationId: designationId,
      role: role,
      department: department,
      isHeadOfDepartment: isHeadOfDepartment,
      password: password,
    );
  }

  // Additional validation methods
  String? validateHomeOfOrigin() {
    if (homeOfOrigin.isEmpty) return 'Home of origin is required';
    return null;
  }

  String? validateDistrict() {
    if (district.isEmpty) return 'District is required';
    return null;
  }

  String? validateCurrentAddress() {
    if (currentAddress.isEmpty) return 'Current address is required';
    return null;
  }

  String? validateDateOfEmployment() {
    if (dateOfEmployment.isEmpty) return 'Date of employment is required';
    return null;
  }

  String? validateDesignation(String? value) {
    if (value == null || value.isEmpty) return 'Designation is required';
    return null;
  }

  // Getters for dropdown data
  List<String> getRoles() => _registerService.getRoles();
  List<String> getDepartments() => _registerService.getDepartments();
  List<String> getGenders() => ['male', 'female', 'other'];
  List<String> getMaritalStatuses() => ['single', 'married', 'divorced', 'widowed'];

  // Reset form data
  void resetForm() {
    employeeNumber = '';
    nationalId = '';
    suffix = '';
    firstName = '';
    surName = '';
    otherNames = '';
    dateOfBirth = '';
    gender = '';
    email = '';
    phone = '';
    homeOfOrigin = '';
    traditionalAuthority = '';
    district = '';
    currentAddress = '';
    maritalStatus = '';
    spouseName = '';
    spouseContact = '';
    dateOfEmployment = '';
    designationId = '';
    role = '';
    department = '';
    isHeadOfDepartment = false;
    password = '';
  }
}
