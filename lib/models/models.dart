import 'package:flutter/foundation.dart';
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
      userId: (json['user_id'] as String?) ??
          (json['employee_id'] as String?) ??
          '',
      date: DateTime.parse(json['date']),
      checkInTime: json['check_in_time'] != null 
          ? DateTime.parse('${json['date']}T${json['check_in_time']}')
          : null,
      checkOutTime: json['check_out_time'] != null 
          ? DateTime.parse('${json['date']}T${json['check_out_time']}')
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

// Shift utility class - matches backend ShiftTimes class
class ShiftUtils {
  // Day Shift Times
  static const TimeOfDay dayShiftCheckInEarliest = TimeOfDay(hour: 6, minute: 0);    // 06:00 AM
  static const TimeOfDay dayShiftCheckInLatest = TimeOfDay(hour: 7, minute: 45);    // 07:45 AM
  static const TimeOfDay dayShiftStart = TimeOfDay(hour: 7, minute: 30);            // 07:30 AM (official start)
  static const TimeOfDay dayShiftEnd = TimeOfDay(hour: 16, minute: 30);             // 04:30 PM (official end)
  static const TimeOfDay dayShiftCheckOutEarliest = TimeOfDay(hour: 16, minute: 0); // 04:00 PM
  static const TimeOfDay dayShiftCheckOutLatest = TimeOfDay(hour: 17, minute: 30);   // 05:30 PM
  static const TimeOfDay dayShiftExtendedStart = TimeOfDay(hour: 17, minute: 30);   // 05:30 PM (extended starts)
  
  // Night Shift Times
  static const TimeOfDay nightShiftStart = TimeOfDay(hour: 16, minute: 30);         // 04:30 PM
  static const TimeOfDay nightShiftEnd = TimeOfDay(hour: 7, minute: 30);            // 07:30 AM (next day)
  static const TimeOfDay nightShiftCheckOutEarliest = TimeOfDay(hour: 6, minute: 0); // 06:00 AM
  static const TimeOfDay nightShiftCheckOutLatest = TimeOfDay(hour: 8, minute: 0);   // 08:00 AM
  static const TimeOfDay nightShiftExtendedStart = TimeOfDay(hour: 8, minute: 0);    // 08:00 AM (extended starts)
  
  static String getCurrentShift() {
    final now = TimeOfDay.now();
    return _getShiftForTime(now);
  }
  
  static String getShiftForDateTime(DateTime dateTime) {
    final timeOfDay = TimeOfDay(hour: dateTime.hour, minute: dateTime.minute);
    return _getShiftForTime(timeOfDay);
  }
  
  static String _getShiftForTime(TimeOfDay time) {
    final hour = time.hour;
    final minute = time.minute;
    
    // Day shift: 06:00 to 16:29 (before night shift starts at 16:30)
    if ((hour > 6) || (hour == 6 && minute >= 0)) {
      if ((hour < 16) || (hour == 16 && minute < 30)) {
        return 'Day Shift';
      }
    }
    
    // Night shift: 16:30 to 05:59 (next day)
    return 'Night Shift';
  }
  
  static bool isWithinShiftGracePeriod(DateTime checkInTime, String expectedShift) {
    final actualShift = getShiftForDateTime(checkInTime);
    return actualShift == expectedShift;
  }
  
  static String determineShiftForAttendance(DateTime checkInTime, DateTime? checkOutTime) {
    // Primary shift based on check-in time
    final primaryShift = getShiftForDateTime(checkInTime);

    // If check-out is provided, check for extended shift
    if (checkOutTime != null) {
      final checkOutHour = checkOutTime.hour;
      final checkOutMinute = checkOutTime.minute;

      if (primaryShift == 'Day Shift') {
        // Day shift: extended only if checkout after 17:30
        if (checkOutHour > 17 || (checkOutHour == 17 && checkOutMinute >= 30)) {
          return '$primaryShift → Extended';
        }
      } else if (primaryShift == 'Night Shift') {
        // Night shift: extended if checkout after 08:00
        if (checkOutHour > 8 || (checkOutHour == 8 && checkOutMinute >= 0)) {
          return '$primaryShift → Extended';
        }
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
      case 'Day Shift → Extended':
        return 'Extended: ${_formatTime(dayShiftStart)} → Late';
      case 'Night Shift → Extended':
        return 'Extended: ${_formatTime(nightShiftStart)} → Late';
      // Legacy support for old format
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

  AppUser copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? role,
    String? department,
    String? profileImage,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      department: department ?? this.department,
      profileImage: profileImage ?? this.profileImage,
    );
  }

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

class PublicHoliday {
  final String id;
  final String name;
  final DateTime date;
  final String? description;
  final String? type; // 'national', 'religious', 'custom'
  final String category; // 'public' or 'institutional'
  final String? source; // Source for public holidays
  final bool isRecurring; // yearly recurring
  final DateTime? createdAt;
  final String? createdBy;

  PublicHoliday({
    required this.id,
    required this.name,
    required this.date,
    this.description,
    this.type,
    this.category = 'institutional',
    this.source,
    this.isRecurring = false,
    this.createdAt,
    this.createdBy,
  });

  factory PublicHoliday.fromJson(Map<String, dynamic> json) {

    try {
      final holiday = PublicHoliday(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        date: DateTime.parse(json['date']),
        description: json['description'] as String?,
        type: json['type'] as String?,
        category: json['category'] as String? ?? 'institutional',
        source: json['source'] as String?,
        isRecurring: json['isRecurring'] as bool? ?? json['is_recurring'] as bool? ?? false, // Try both field names
        createdAt: json['created_at'] != null 
            ? DateTime.parse(json['created_at'])
            : null,
        createdBy: json['created_by'] as String?,
      );
      if (kDebugMode) {
        print('Successfully parsed PublicHoliday: ${holiday.name}');
      }
      return holiday;
    } catch (e) {

      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'date': date.toIso8601String().split('T')[0],
      'description': description,
      'type': type,
      'category': category,
      'source': source,
      'is_recurring': isRecurring,
      'created_at': createdAt?.toIso8601String(),
      'created_by': createdBy,
    };
  }

  // Helper to check if a date matches this holiday (considering recurring)
  bool matchesDate(DateTime checkDate) {
    if (isRecurring) {
      return checkDate.month == date.month && checkDate.day == date.day;
    }
    return checkDate.year == date.year && 
           checkDate.month == date.month && 
           checkDate.day == date.day;
  }
}

class Announcement {
  final String id;
  final String title;
  final String message;
  final String type; // 'general', 'urgent', 'policy', 'event'
  final String? targetDepartment; // null means all departments
  final String? targetRole; // optional role targeting
  final bool isActive;
  final DateTime? expiresAt; // optional expiration date
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? createdBy;
  final String? attachmentUrl; // optional file attachment

  Announcement({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.targetDepartment,
    this.targetRole,
    this.isActive = true,
    this.expiresAt,
    required this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.attachmentUrl,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    try {

      final announcement = Announcement(
        id: json['id']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        message: json['message']?.toString() ?? '',
        type: json['type']?.toString() ?? 'general',
        targetDepartment: json['targetAudience']?.toString(), // Updated to match backend
        targetRole: json['target_role']?.toString(),
        isActive: json['isActive'] as bool? ?? true, // Updated to match backend
        expiresAt: json['expires_at'] != null 
            ? DateTime.parse(json['expires_at'].toString())
            : null,
        createdAt: DateTime.parse(json['createdAt']?.toString() ?? DateTime.now().toIso8601String()), // Updated to match backend
        updatedAt: json['updatedAt'] != null 
            ? DateTime.parse(json['updatedAt'].toString())
            : null,
        createdBy: json['authorName']?.toString(), // Updated to match backend
        attachmentUrl: json['attachment_url']?.toString(),
      );
      
      return announcement;
    } catch (e) {

      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type,
      'target_department': targetDepartment,
      'target_role': targetRole,
      'is_active': isActive,
      'expires_at': expiresAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'created_by': createdBy,
      'attachment_url': attachmentUrl,
    };
  }

  // Helper to check if announcement is still valid
  bool get isValid {
    if (!isActive) return false;
    if (expiresAt != null && DateTime.now().isAfter(expiresAt!)) return false;
    return true;
  }

  // Helper to get display text for target audience
  String get targetAudience {
    if (targetDepartment != null && targetRole != null) {
      return '$targetDepartment - $targetRole';
    } else if (targetDepartment != null) {
      return targetDepartment!;
    } else if (targetRole != null) {
      return targetRole!;
    } else {
      return 'All Staff';
    }
  }

  // Helper to get type display text
  String get typeDisplay {
    switch (type) {
      case 'holiday':
        return '🎉 Holiday';
      case 'urgent':
        return '🚨 Urgent';
      case 'policy':
        return '📋 Policy Update';
      case 'event':
        return '🎉 Event';
      default:
        return '📢 General';
    }
  }

  // Helper to get type color
  String get typeColor {
    switch (type) {
      case 'holiday':
        return '#4CAF50'; // Green for holidays
      case 'urgent':
        return '#FF5252'; // Red
      case 'policy':
        return '#2196F3'; // Blue
      case 'event':
        return '#4CAF50'; // Green
      default:
        return '#FF9800'; // Orange
    }
  }
}
