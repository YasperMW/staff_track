import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class Role {
  final String roleId;
  final String name;
  final String createdAt;

  Role({
    required this.roleId,
    required this.name,
    required this.createdAt,
  });

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
      roleId: json['role_id'] as String,
      name: json['name'] as String,
      createdAt: json['created_at'] as String,
    );
  }
}

class Department {
  final String departmentId;
  final String name;
  final String? description;
  final String createdAt;
  final List<String> designations;

  Department({
    required this.departmentId,
    required this.name,
    this.description,
    required this.createdAt,
    required this.designations,
  });

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      departmentId: json['department_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      createdAt: json['created_at'] as String,
      designations: List<String>.from(json['designations'] as List),
    );
  }
}

class Designation {
  final String designationId;
  final String name;
  final String? description;
  final String departmentId;
  final String createdAt;

  Designation({
    required this.designationId,
    required this.name,
    this.description,
    required this.departmentId,
    required this.createdAt,
  });

  factory Designation.fromJson(Map<String, dynamic> json) {
    return Designation(
      designationId: json['designation_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      departmentId: json['department_id'] as String,
      createdAt: json['created_at'] as String,
    );
  }
}

class Grade {
  final String id;
  final String name;
  final int annualLeaveDays;

  Grade({
    required this.id,
    required this.name,
    required this.annualLeaveDays,
  });

  factory Grade.fromJson(Map<String, dynamic> json) {
    return Grade(
      id: json['id'] as String,
      name: json['name'] as String,
      annualLeaveDays: json['annual_leave_days'] as int,
    );
  }
}

class LookupService {
  static Future<List<Grade>> getGrades() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/auth/grades'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((g) => Grade.fromJson(g)).toList();
      } else {
        throw Exception('Failed to load grades: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching grades: $e');
      }
      return [];
    }
  }

  static Future<List<Role>> getRoles() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/lookup/roles'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final rolesList = data['roles'] as List;
        return rolesList.map((role) => Role.fromJson(role)).toList();
      } else {
        throw Exception('Failed to load roles: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching roles: $e');
      }
      return [];
    }
  }

  static Future<List<Department>> getDepartments() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/lookup/departments'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final departmentsList = data['departments'] as List;
        return departmentsList.map((dept) => Department.fromJson(dept)).toList();
      } else {
        throw Exception('Failed to load departments: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching departments: $e');
      }
      return [];
    }
  }

  static Future<List<Designation>> getDesignationsByDepartment(String departmentId) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/lookup/designations?department_id=$departmentId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final designationsList = data['designations'] as List;
        return designationsList.map((designation) => Designation.fromJson(designation)).toList();
      } else {
        if (kDebugMode) {
        print('Failed to load designations: ${response.statusCode}');

          print('Response body: ${response.body}');
        }
        return [];
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching designations: $e');
      }
      return [];
    }
  }

  static Future<List<Designation>> getAllDesignations() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/lookup/designations'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final designationsList = data['designations'] as List;
        return designationsList.map((designation) => Designation.fromJson(designation)).toList();
      } else {
        if (kDebugMode) {
          print('Failed to load designations: ${response.statusCode}');

        print('Response body: ${response.body}');
        }
        return [];
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching designations: $e');
      }
      return [];
    }
  }
}
