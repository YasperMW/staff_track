import 'package:flutter/foundation.dart';
import '../controllers/attendance_controller.dart';
import '../models/models.dart';

/// Feature-focused attendance service that wraps the lower-level
/// [AttendanceController] HTTP layer.
class AttendanceService {
  const AttendanceService();

  Future<AttendanceRecord?> getTodayAttendance() async {
    debugPrint('🔍 [AttendanceService] Fetching today\'s attendance...');
    try {
      final attendances = await AttendanceController.getTodayAttendance();
      debugPrint('📊 [AttendanceService] Received ${attendances.length} attendance records');
      
      if (attendances.isEmpty) {
        debugPrint('❌ [AttendanceService] No attendance records found for today');
        return null;
      }

      // Prefer an active (checked-in, not checked-out) record if any.
      final active = attendances.where((a) => a.isCheckedIn && !a.isCheckedOut).toList();
      if (active.isNotEmpty) {
        final attendance = active.first;
        debugPrint('✅ [AttendanceService] Using active attendance record');
        return attendance;
      }

      // Prefer record for the current shift. This enables a new shift check-in
      // after completing an earlier shift on the same day.
      final currentShift = ShiftUtils.getCurrentShift();
      final currentShiftRecords = attendances
          .where((a) => (a.shiftType ?? '').trim() == currentShift)
          .toList();
      if (currentShiftRecords.isNotEmpty) {
        final attendance = currentShiftRecords.first;
        debugPrint('✅ [AttendanceService] Using current shift attendance record ($currentShift)');
        return attendance;
      }

      // If there are only completed records and none for the current shift,
      // return null so the UI offers a fresh check-in for the current shift.
      debugPrint('ℹ️ [AttendanceService] No record for current shift ($currentShift); allowing new check-in');
      return null;
    } catch (e) {
      debugPrint('💥 [AttendanceService] Error fetching today\'s attendance: $e');
      rethrow;
    }
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

  Future<Map<String, dynamic>> getMyProfileMetrics() {
    return AttendanceController.getMyProfileMetrics();
  }
}

