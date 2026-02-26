import 'package:flutter/material.dart';

enum RequestStatus { pending, approved, rejected }

class UserRequest {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final RequestStatus status;
  final String type;

  UserRequest({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.status,
    required this.type,
  });
}

class AttendanceRecord {
  final String id;
  final String userId;
  final DateTime date;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final String? location;
  final double? workHours;
  final String? deviceId;
  final double? accuracy;
  final String? shiftType;

  AttendanceRecord({
    required this.id,
    required this.userId,
    required this.date,
    this.checkInTime,
    this.checkOutTime,
    this.location,
    this.workHours,
    this.deviceId,
    this.accuracy,
    this.shiftType,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['attendance_log_id'] ?? '',
      userId: '', // Will be set from auth context
      date: DateTime.parse(json['date']),
      checkInTime: json['check_in_time'] != null 
          ? DateTime.parse('${json['date']} ${json['check_in_time']}')
          : null,
      checkOutTime: json['check_out_time'] != null 
          ? DateTime.parse('${json['date']} ${json['check_out_time']}')
          : null,
      location: json['location'],
      workHours: json['work_hours']?.toDouble(),
      deviceId: json['device_id'],
      accuracy: json['accuracy']?.toDouble(),
      shiftType: json['shift_type'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'attendance_log_id': id,
      'date': date.toIso8601String().split('T')[0],
      'check_in_time': checkInTime != null 
          ? '${checkInTime!.hour.toString().padLeft(2, '0')}:${checkInTime!.minute.toString().padLeft(2, '0')}:${checkInTime!.second.toString().padLeft(2, '0')}'
          : null,
      'check_out_time': checkOutTime != null 
          ? '${checkOutTime!.hour.toString().padLeft(2, '0')}:${checkOutTime!.minute.toString().padLeft(2, '0')}:${checkOutTime!.second.toString().padLeft(2, '0')}'
          : null,
      'location': location,
      'work_hours': workHours,
      'device_id': deviceId,
      'accuracy': accuracy,
      'shift_type': shiftType,
    };
  }

  bool get isCheckedIn => checkInTime != null;
  bool get isCheckedOut => checkOutTime != null;
  bool get isComplete => isCheckedIn && isCheckedOut;
}

// Shift utility class
class ShiftUtils {
  static const TimeOfDay dayShiftStart = TimeOfDay(hour: 7, minute: 30);
  static const TimeOfDay dayShiftEnd = TimeOfDay(hour: 16, minute: 30);
  static const TimeOfDay nightShiftStart = TimeOfDay(hour: 16, minute: 30);
  static const TimeOfDay nightShiftEnd = TimeOfDay(hour: 7, minute: 30);
  
  static String getCurrentShift() {
    final now = TimeOfDay.now();
    return _getShiftForTime(now);
  }
  
  static String getShiftForDateTime(DateTime dateTime) {
    final timeOfDay = TimeOfDay(hour: dateTime.hour, minute: dateTime.minute);
    return _getShiftForTime(timeOfDay);
  }
  
  static String _getShiftForTime(TimeOfDay time) {
    final currentMinutes = time.hour * 60 + time.minute;
    final dayStartMinutes = dayShiftStart.hour * 60 + dayShiftStart.minute;
    final dayEndMinutes = dayShiftEnd.hour * 60 + dayShiftEnd.minute;
    
    // Day shift: 07:30 to 16:30
    if (currentMinutes >= dayStartMinutes && currentMinutes < dayEndMinutes) {
      return 'Day Shift';
    }
    // Night shift: 16:30 to 07:30 (next day)
    else {
      return 'Night Shift';
    }
  }
  
  static bool isWithinShiftGracePeriod(DateTime checkInTime, String expectedShift) {
    final actualShift = getShiftForDateTime(checkInTime);
    return actualShift == expectedShift;
  }
  
  static String determineShiftForAttendance(DateTime checkInTime, DateTime? checkOutTime) {
    // Primary shift based on check-in time
    final primaryShift = getShiftForDateTime(checkInTime);
    
    // If check-out is in different shift and significantly late, consider mixed shift
    if (checkOutTime != null) {
      final checkOutShift = getShiftForDateTime(checkOutTime);
      final durationDifference = checkOutTime.difference(checkInTime);
      
      // If worked across shift boundary for more than 2 hours, mark as mixed
      if (primaryShift != checkOutShift && durationDifference.inHours > 2) {
        return '$primaryShift → $checkOutShift';
      }
    }
    
    return primaryShift;
  }
  
  static String getShiftTimeRange(String shiftType) {
    switch (shiftType) {
      case 'Day Shift':
        return '${_formatTime(dayShiftStart)} - ${_formatTime(dayShiftEnd)}';
      case 'Night Shift':
        return '${_formatTime(nightShiftStart)} - ${_formatTime(nightShiftEnd)}';
      case 'Day Shift → Night Shift':
        return 'Extended: ${_formatTime(dayShiftStart)} → Late';
      case 'Night Shift → Day Shift':
        return 'Extended: ${_formatTime(nightShiftStart)} → Late';
      default:
        return 'N/A';
    }
  }
  
  static String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
  
  static DateTime getShiftStartDateTime(String shiftType, DateTime date) {
    switch (shiftType) {
      case 'Day Shift':
        return DateTime(date.year, date.month, date.day, dayShiftStart.hour, dayShiftStart.minute);
      case 'Night Shift':
        // Night shift starts at 16:30, but if it's after midnight, it belongs to previous day
        if (date.hour < nightShiftEnd.hour || (date.hour == nightShiftEnd.hour && date.minute <= nightShiftEnd.minute)) {
          return DateTime(date.year, date.month, date.day - 1, nightShiftStart.hour, nightShiftStart.minute);
        }
        return DateTime(date.year, date.month, date.day, nightShiftStart.hour, nightShiftStart.minute);
      default:
        return date;
    }
  }
}

class AppUser {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String role;
  final String department;
  final String profileImage;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    required this.department,
    required this.profileImage,
  });

  bool get isApprover {
    final approverRoles = [
      'HR Admin',
      'Medical Director',
      'Department Supervisor',
      'Doctor',
      'Accountant',
      'Principal Hospital Administrator',
      'System Admin',
    ];
    return approverRoles.contains(role);
  }
}

class TeamAttendanceMember {
  final String userId;
  final String name;
  final String role;
  final String status;
  final String? checkInTime;
  final String? checkOutTime;

  TeamAttendanceMember({
    required this.userId,
    required this.name,
    required this.role,
    required this.status,
    this.checkInTime,
    this.checkOutTime,
  });

  factory TeamAttendanceMember.fromJson(Map<String, dynamic> json) {
    return TeamAttendanceMember(
      userId: json['user_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      role: json['role'] as String? ?? '',
      status: json['status'] as String? ?? '',
      checkInTime: json['check_in_time'] as String?,
      checkOutTime: json['check_out_time'] as String?,
    );
  }
}
