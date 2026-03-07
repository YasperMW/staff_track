import '../controllers/attendance_controller.dart';
import '../models/models.dart';

/// Feature-focused attendance service that wraps the lower-level
/// [AttendanceController] HTTP layer.
class AttendanceService {
  const AttendanceService();

  Future<AttendanceRecord?> getTodayAttendance() {
    return AttendanceController.getTodayAttendance();
  }

  Future<List<AttendanceRecord>> getAttendanceHistory({
    String? startDate,
    String? endDate,
    int limit = 30,
  }) {
    return AttendanceController.getAttendanceHistory(
      startDate: startDate,
      endDate: endDate,
      limit: limit,
    );
  }

  Future<Map<String, dynamic>> getAttendanceSummary({
    String? startDate,
    String? endDate,
  }) {
    return AttendanceController.getAttendanceSummary(
      startDate: startDate,
      endDate: endDate,
    );
  }

  Future<Map<String, dynamic>> getTeamTodaySummary() {
    return AttendanceController.getTeamTodaySummary();
  }

  Future<List<TeamAttendanceMember>> getTeamTodayList() {
    return AttendanceController.getTeamTodayList();
  }
}

