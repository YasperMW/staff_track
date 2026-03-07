import 'package:flutter/foundation.dart';

import '../models/models.dart';
import '../services/attendance_service.dart';

class AttendanceProvider extends ChangeNotifier {
  final AttendanceService _attendanceService;

  AttendanceProvider({AttendanceService? attendanceService})
      : _attendanceService = attendanceService ?? const AttendanceService();
  AttendanceRecord? _todayAttendance;
  bool _isLoadingToday = false;
  String? _todayError;

  List<AttendanceRecord> _recentAttendance = [];
  bool _isLoadingRecent = false;
  String? _recentError;

  AttendanceRecord? get todayAttendance => _todayAttendance;
  bool get isLoadingToday => _isLoadingToday;
  String? get todayError => _todayError;

  List<AttendanceRecord> get recentAttendance => _recentAttendance;
  bool get isLoadingRecent => _isLoadingRecent;
  String? get recentError => _recentError;

  Future<void> loadTodayAttendance() async {
    _isLoadingToday = true;
    _todayError = null;
    notifyListeners();

    try {
      final attendance = await _attendanceService.getTodayAttendance();
      _todayAttendance = attendance;
    } catch (e) {
      _todayError = e.toString();
    } finally {
      _isLoadingToday = false;
      notifyListeners();
    }
  }

  Future<void> loadRecentAttendance({int limit = 5}) async {
    _isLoadingRecent = true;
    _recentError = null;
    notifyListeners();

    try {
      final history =
          await _attendanceService.getAttendanceHistory(limit: limit);
      _recentAttendance = history;
    } catch (e) {
      _recentError = e.toString();
    } finally {
      _isLoadingRecent = false;
      notifyListeners();
    }
  }

  void clear() {
    _todayAttendance = null;
    _recentAttendance = [];
    _todayError = null;
    _recentError = null;
    _isLoadingToday = false;
    _isLoadingRecent = false;
    notifyListeners();
  }
}

