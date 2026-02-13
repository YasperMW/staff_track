import '../models/models.dart';

class MockData {
  static AppUser currentUser = employeeUser;

  static final AppUser adminUser = AppUser(
    id: 'ADM001',
    name: 'Dr. Sarah Wilson',
    email: 'admin@hospital.com',
    role: 'Medical Director',
    department: 'Administration',
    profileImage: 'https://i.pravatar.cc/150?u=sarah',
  );

  static final AppUser employeeUser = AppUser(
    id: 'EMP123',
    name: 'Alex Johnson',
    email: 'employee@hospital.com',
    role: 'Nurse',
    department: 'Emergency',
    profileImage: 'https://i.pravatar.cc/150?u=alex',
  );

  static final List<String> roles = [
    'HR Admin',
    'Medical Director',
    'Department Supervisor',
    'Doctor',
    'Nurse',
    'Clinical Officer',
    'Support Staff',
    'Accountant',
    'Principal Hospital Administrator',
    'System Admin',
  ];

  static final List<String> departments = [
    'Administration',
    'Emergency',
    'Cardiology',
    'Pediatrics',
    'Surgery',
    'Radiology',
    'Pharmacy',
    'Nursing',
  ];

  static bool login(String email, String password) {
    if (email == 'admin@hospital.com' && password == 'admin123') {
      currentUser = adminUser;
      return true;
    } else if (email == 'employee@hospital.com' && password == 'emp123') {
      currentUser = employeeUser;
      return true;
    }
    return false;
  }

  static final List<UserRequest> requests = [
    UserRequest(
      id: 'REQ001',
      title: 'Annual Leave',
      description: 'Requesting leave for summer vacation.',
      date: DateTime.now().subtract(const Duration(days: 5)),
      status: RequestStatus.approved,
      type: 'Leave',
    ),
  ];

  static final List<Map<String, dynamic>> recentActivity = [
    {
      'day': 'Today',
      'time': '08:55 AM — --:--',
      'status': 'Active',
    },
    {
      'day': 'Yesterday',
      'time': '09:02 AM — 06:15 PM',
      'status': 'Completed',
    },
    {
      'day': 'Mon, Feb 7',
      'time': '08:48 AM — 05:58 PM',
      'status': 'Completed',
    },
  ];
  static final List<Map<String, dynamic>> requestsHistory = [
    {
      'type': 'Annual Leave',
      'dateRange': 'Feb 15 — Feb 17',
      'duration': '3d',
      'description': 'Family vacation',
      'status': 'Pending',
    },
    {
      'type': 'Sick Leave',
      'dateRange': 'Jan 20 — Jan 20',
      'duration': '1d',
      'description': 'Flu',
      'status': 'Approved',
    },
    {
      'type': 'Work from Home',
      'dateRange': 'Jan 15 — Jan 15',
      'duration': '1d',
      'description': 'Plumber visit',
      'status': 'Approved',
    },
    {
      'type': 'Annual Leave',
      'dateRange': 'Dec 24 — Dec 26',
      'duration': '3d',
      'description': 'Christmas holidays',
      'status': 'Rejected',
    },
  ];

  static final List<Map<String, dynamic>> attendanceHistory = [
    {
      'date': 'Mon, Feb 9',
      'time': '08:55 AM - 06:10 PM',
      'location': 'Office',
      'totalHours': '9h 15m total',
      'status': 'On Time',
    },
    {
      'date': 'Fri, Feb 6',
      'time': '09:02 AM - 06:15 PM',
      'location': 'Office',
      'totalHours': '9h 13m total',
      'status': 'On Time',
    },
    {
      'date': 'Thu, Feb 5',
      'time': '09:18 AM - 06:30 PM',
      'location': 'Remote',
      'totalHours': '9h 12m total',
      'status': 'Late',
    },
    {
      'date': 'Wed, Feb 4',
      'time': '08:48 AM - 05:58 PM',
      'location': 'Office',
      'totalHours': '9h 10m total',
      'status': 'On Time',
    },
    {
      'date': 'Tue, Feb 3',
      'time': '08:50 AM - 06:05 PM',
      'location': 'Office',
      'totalHours': '9h 15m total',
      'status': 'On Time',
    },
    {
      'date': 'Mon, Feb 2',
      'time': '09:30 AM - 06:45 PM',
      'location': 'Remote',
      'totalHours': '9h 15m total',
      'status': 'Late',
    },
  ];
}
