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
    };
  }

  bool get isCheckedIn => checkInTime != null;
  bool get isCheckedOut => checkOutTime != null;
  bool get isComplete => isCheckedIn && isCheckedOut;
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
