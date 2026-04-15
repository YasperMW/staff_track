import 'package:flutter/material.dart';

/// Validation utility class providing form field validators
/// with detailed error messages for active user feedback.
class Validators {
  Validators._();

  // Email regex pattern
  static final _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  // Phone regex pattern (supports various formats including +265)
  static final _phoneRegex = RegExp(
    r'^\+?[0-9\s\-\(\)]{9,15}$',
  );

  // Name regex (letters, spaces, hyphens, apostrophes only)
  static final _nameRegex = RegExp(
    r"^[a-zA-Z\s\-']+$",
  );

  /// Validates email format
  /// Returns null if valid, error message if invalid
  static FormFieldValidator<String> email({bool required = true}) {
    return (String? value) {
      if (value == null || value.trim().isEmpty) {
        return required ? 'Email is required' : null;
      }
      if (!_emailRegex.hasMatch(value.trim())) {
        return 'Please enter a valid email address';
      }
      return null;
    };
  }

  /// Validates phone number format
  /// Returns null if valid, error message if invalid
  static FormFieldValidator<String> phone({bool required = true}) {
    return (String? value) {
      if (value == null || value.trim().isEmpty) {
        return required ? 'Phone number is required' : null;
      }
      final cleanNumber = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
      if (!_phoneRegex.hasMatch(value.trim())) {
        return 'Please enter a valid phone number';
      }
      if (cleanNumber.length < 9) {
        return 'Phone number too short (min 9 digits)';
      }
      return null;
    };
  }

  /// Validates password strength
  /// minLength: minimum password length (default 6)
  /// requireNumber: whether to require at least one number
  /// requireLetter: whether to require at least one letter
  static FormFieldValidator<String> password({
    int minLength = 6,
    bool requireNumber = true,
    bool requireLetter = true,
  }) {
    return (String? value) {
      if (value == null || value.isEmpty) {
        return 'Password is required';
      }
      if (value.length < minLength) {
        return 'Password must be at least $minLength characters';
      }
      if (requireLetter && !value.contains(RegExp(r'[a-zA-Z]'))) {
        return 'Password must contain at least one letter';
      }
      if (requireNumber && !value.contains(RegExp(r'[0-9]'))) {
        return 'Password must contain at least one number';
      }
      return null;
    };
  }

  /// Validates that confirm password matches password
  static FormFieldValidator<String> confirmPassword(
    TextEditingController passwordController, {
    bool required = true,
  }) {
    return (String? value) {
      if (value == null || value.isEmpty) {
        return required ? 'Please confirm your password' : null;
      }
      if (value != passwordController.text) {
        return 'Passwords do not match';
      }
      return null;
    };
  }

  /// Validates name fields (letters only)
  static FormFieldValidator<String> name(
    String fieldName, {
    int minLength = 2,
    bool required = true,
  }) {
    return (String? value) {
      if (value == null || value.trim().isEmpty) {
        return required ? '$fieldName is required' : null;
      }
      if (value.trim().length < minLength) {
        return '$fieldName must be at least $minLength characters';
      }
      if (!_nameRegex.hasMatch(value.trim())) {
        return '$fieldName can only contain letters';
      }
      return null;
    };
  }

  /// Validates employee ID
  static FormFieldValidator<String> employeeId({bool required = true}) {
    return (String? value) {
      if (value == null || value.trim().isEmpty) {
        return required ? 'Employee ID is required' : null;
      }
      if (value.trim().length < 3) {
        return 'Employee ID must be at least 3 characters';
      }
      return null;
    };
  }

  /// Validates national ID
  static FormFieldValidator<String> nationalId({bool required = true}) {
    return (String? value) {
      if (value == null || value.trim().isEmpty) {
        return required ? 'National ID is required' : null;
      }
      if (value.trim().length < 6) {
        return 'National ID must be at least 6 characters';
      }
      return null;
    };
  }

  /// Validates required fields
  static FormFieldValidator<String> required(String fieldName) {
    return (String? value) {
      if (value == null || value.trim().isEmpty) {
        return '$fieldName is required';
      }
      return null;
    };
  }

  /// Validates optional fields (always returns null)
  static FormFieldValidator<String> optional() {
    return (String? value) => null;
  }

  /// Combines multiple validators, returns first error found
  static FormFieldValidator<String> combine(
    List<FormFieldValidator<String>> validators,
  ) {
    return (String? value) {
      for (final validator in validators) {
        final error = validator(value);
        if (error != null) return error;
      }
      return null;
    };
  }
}

/// Enum for validation types used in ValidatedTextField
enum ValidationType {
  email,
  phone,
  password,
  confirmPassword,
  name,
  employeeId,
  nationalId,
  required,
  optional,
  none,
}