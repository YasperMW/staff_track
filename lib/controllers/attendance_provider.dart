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

  Map<String, dynamic>? _profileMetrics;
  bool _isLoadingMetrics = false;
  String? _metricsError;

  AttendanceRecord? get todayAttendance => _todayAttendance;
  bool get isLoadingToday => _isLoadingToday;
  String? get todayError => _todayError;

  List<AttendanceRecord> get recentAttendance => _recentAttendance;
  bool get isLoadingRecent => _isLoadingRecent;
  String? get recentError => _recentError;

  Map<String, dynamic>? get profileMetrics => _profileMetrics;
  bool get isLoadingMetrics => _isLoadingMetrics;
  String? get metricsError => _metricsError;

  Future<void> loadTodayAttendance() async {
    debugPrint('🔄 [AttendanceProvider] Starting loadTodayAttendance...');
    _isLoadingToday = true;
    _todayError = null;
    debugPrint('📢 [AttendanceProvider] Notifying listeners - loading state');
    notifyListeners();

    try {
      final attendance = await _attendanceService.getTodayAttendance();
      _todayAttendance = attendance;
      debugPrint('✅ [AttendanceProvider] Successfully loaded today\'s attendance');
    } catch (e) {
      _todayError = e.toString();
      debugPrint('❌ [AttendanceProvider] Error loading today\'s attendance: $e');
    } finally {
      _isLoadingToday = false;
      debugPrint('📢 [AttendanceProvider] Notifying listeners - completed state');
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

  Future<void> loadProfileMetrics() async {
    _isLoadingMetrics = true;
    _metricsError = null;
    notifyListeners();

    try {
      final metrics = await _attendanceService.getMyProfileMetrics();
      _profileMetrics = metrics;
    } catch (e) {
      _metricsError = e.toString();
    } finally {
      _isLoadingMetrics = false;
      notifyListeners();
    }
  }

  void clear() {
    _todayAttendance = null;
    _recentAttendance = [];
    _todayError = null;
    _recentError = null;
    _profileMetrics = null;
    _metricsError = null;
    _isLoadingToday = false;
    _isLoadingRecent = false;
    _isLoadingMetrics = false;
    notifyListeners();
  }
}

