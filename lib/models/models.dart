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

class CheckInRecord {
  final DateTime timestamp;
  final String location;
  final bool isCheckIn;

  CheckInRecord({
    required this.timestamp,
    required this.location,
    required this.isCheckIn,
  });
}

class AppUser {
  final String id;
  final String name;
  final String email;
  final String role;
  final String department;
  final String profileImage;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.department,
    required this.profileImage,
  });
}
