import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../controllers/attendance_controller.dart';
import '../../models/models.dart';
import '../../widgets/floating_navigation.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/simple_header.dart';
import '../services/permission_service.dart';
import 'attendance_history_screen.dart';
import 'home_screen.dart';

class CheckInOutScreen extends StatefulWidget {
  const CheckInOutScreen({super.key});

  @override
  State<CheckInOutScreen> createState() => _CheckInOutScreenState();
}

class _CheckInOutScreenState extends State<CheckInOutScreen> {
  List<AttendanceRecord> todayAttendances = [];
  bool isLoading = false;
  bool isGettingLocation = false;
  String? currentLocation;
  Position? currentPosition;
  String currentShift = '';
  String shiftTimeRange = '';
  Timer? _timer;

  AlertDialog _buildUniformDialog({
    required String title,
    required Widget content,
    required Widget primaryAction,
    String cancelText = 'Cancel',
    VoidCallback? onCancel,
  }) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      content: DefaultTextStyle(
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.75),
          fontSize: 14,
        ),
        child: content,
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () {
                  onCancel?.call();
                  Navigator.of(context).pop();
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(cancelText),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: primaryAction,
            ),
          ],
        ),
      ],
    );
  }

  // Constants for shift times
  static const int dayShiftLateHour = 9; // Late if checking in after 09:00
  static const int dayShiftEndHour = 16;
  static const int dayShiftEndMinute = 30; // Day shift ends at 16:30
  static const int nightShiftLateHour = 18; // Late if checking in after 18:00
  static const int nightShiftEndHour = 7;
  static const int nightShiftEndMinute = 30; // Night shift ends at 07:30

  @override
  void initState() {
    super.initState();
    _updateShiftInfo();
    _loadTodayAttendance();
    _getCurrentLocation();
    
    // Update time and shift info every second
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        _updateShiftInfo();
        setState(() {}); // Trigger rebuild to update time
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateShiftInfo() {
    setState(() {
      currentShift = ShiftUtils.getCurrentShift();
      shiftTimeRange = ShiftUtils.getShiftTimeRange(currentShift);
    });
  }

  Future<void> _loadTodayAttendance() async {
    setState(() {
      isLoading = true;
    });

    try {
      final attendances = await AttendanceController.getTodayAttendance();

      // Also fetch yesterday's attendance to check for unresolved night shift check-ins
      // This handles the case where someone forgot to check out their night shift yesterday
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      final yesterdayDate = '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';

      try {
        final yesterdayAttendances = await AttendanceController.getAttendanceHistory(
          startDate: yesterdayDate,
          endDate: yesterdayDate,
          limit: 10,
        );

        // Filter for active night shift check-ins from yesterday
        final activeNightShiftCheckIns = yesterdayAttendances.where((a) =>
            a.checkInTime != null &&
            a.checkOutTime == null &&
            (a.shiftType ?? '').contains('Night Shift')
        ).toList();

        if (kDebugMode) {
          debugPrint('DEBUG: Found ${activeNightShiftCheckIns.length} unresolved night shift check-ins from yesterday');
        }

        // Add them to today's attendances (only if not already present from backend)
        for (final checkIn in activeNightShiftCheckIns) {
          if (!attendances.any((a) => a.id == checkIn.id)) {
            attendances.add(checkIn);
          }
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('DEBUG: Failed to fetch yesterday\'s attendance: $e');
        }
        // Continue without yesterday's records - backend should handle this
      }

      setState(() {
        todayAttendances = attendances;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showErrorSnackBar('Failed to load attendance: $e');
    }
  }

  Future<void> _getCurrentLocation() async {
    if (kDebugMode) {
      debugPrint('DEBUG: Starting location capture...');
    }
    setState(() {
      isGettingLocation = true;
    });

    try {
      // Check location services & permission using centralized service
      if (kDebugMode) {
        debugPrint('DEBUG: Checking location access status...');
      }
      final access = await PermissionService.getLocationAccessStatus();
      if (kDebugMode) {
        debugPrint('DEBUG: Location access state: ${access.state}');
      }

      if (access.state != LocationAccessState.ready) {
        throw Exception(access.message);
      }

      // Get current position
      if (kDebugMode) {
        debugPrint('DEBUG: Getting current position...');
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      
      if (kDebugMode) {
        debugPrint('DEBUG: Position obtained:');
        debugPrint('  Latitude: ${position.latitude}');
        debugPrint('  Longitude: ${position.longitude}');
        debugPrint('  Accuracy: ${position.accuracy} meters');
      }

      String locationText =
          'Lat: ${position.latitude.toStringAsFixed(6)}, Lng: ${position.longitude.toStringAsFixed(6)}';

      try {
        if (kDebugMode) {
          debugPrint('DEBUG: Getting address from coordinates...');
        }
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (kDebugMode) {
          debugPrint('DEBUG: Found ${placemarks.length} placemarks');
        }
        
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          if (kDebugMode) {
            debugPrint(
              'DEBUG: Primary placemark: ${place.name}, ${place.locality}, ${place.subAdministrativeArea}',
            );
          }
          
          final parts = <String>[];
          if (place.name != null && place.name!.isNotEmpty) {
            parts.add(place.name!);
          }
          if (place.locality != null && place.locality!.isNotEmpty) {
            parts.add(place.locality!);
          }
          if (place.subAdministrativeArea != null &&
              place.subAdministrativeArea!.isNotEmpty &&
              !parts.contains(place.subAdministrativeArea)) {
            parts.add(place.subAdministrativeArea!);
          }
          if (parts.isNotEmpty) {
            locationText = parts.join(', ');
            if (kDebugMode) {
              debugPrint('DEBUG: Formatted location text: $locationText');
            }
          }
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('DEBUG: Failed to get address: $e');
        }
      }

      if (kDebugMode) {
        debugPrint('DEBUG: Setting location state...');
      }
      setState(() {
        currentPosition = position;
        currentLocation = locationText;
        isGettingLocation = false;
      });
      
      if (kDebugMode) {
        debugPrint('DEBUG: Location capture completed successfully');
        debugPrint('  Final currentLocation: $currentLocation');
        debugPrint('  Final currentPosition: $currentPosition');
      }
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('DEBUG: Location capture failed: $e');
      }
      setState(() {
        isGettingLocation = false;
      });
      _showErrorSnackBar('Failed to get location: $e');
    }
  }

  Future<void> _checkIn() async {
    // Check if late check-in and collect reason if needed
    String? lateReason;
    if (_isLateCheckIn()) {
      lateReason = await _showReasonDialog(
        title: 'Late Check-in',
        message: 'You are checking in late. Please provide a reason for your late arrival.',
        hint: 'e.g., Traffic delay, car trouble, family emergency...',
      );

      // If user cancelled the dialog, abort check-in
      if (lateReason == null) {
        return;
      }
    }

    setState(() {
      isLoading = true;
    });

    // Debug logging before location check
    if (kDebugMode) {
      debugPrint('DEBUG: Check-in initiated with current state:');
      debugPrint('  currentLocation: $currentLocation');
      debugPrint('  currentPosition: $currentPosition');
      debugPrint('  currentPosition.latitude: ${currentPosition?.latitude}');
      debugPrint('  currentPosition.longitude: ${currentPosition?.longitude}');
    }

    // Ensure we have location data before proceeding
    if (currentLocation == null || currentPosition == null) {
      setState(() {
        isLoading = false;
      });
      if (kDebugMode) {
        debugPrint('DEBUG: Location missing, attempting to refresh...');
      }
      _showErrorSnackBar('Location is required for check-in. Please capture location first.');
      return;
    }

    // Debug logging before API call
    if (kDebugMode) {
      debugPrint('DEBUG: About to call AttendanceController.checkIn with:');
      debugPrint('  location: $currentLocation');
      debugPrint('  latitude: ${currentPosition?.latitude}');
      debugPrint('  longitude: ${currentPosition?.longitude}');
      debugPrint('  currentShift: $currentShift');
      debugPrint('  lateReason: $lateReason');
    }

    final result = await AttendanceController.checkIn(
      location: currentLocation,
      latitude: currentPosition?.latitude,
      longitude: currentPosition?.longitude,
      shiftType: currentShift,
      lateReason: lateReason,
    );

    setState(() {
      isLoading = false;
    });

    if (result.isSuccess) {
      final data = result.data!;
      _showSuccessSnackBar(
        'Check-in successful for $currentShift at ${data['check_in_time']}',
      );
      _loadTodayAttendance(); // Refresh data
      return;
    }

    final error = result.error!;
    if (kDebugMode) {
      debugPrint('DEBUG: Check-in error: ${error.code} - ${error.message}');
    }

    switch (error.code) {
      case 'outside_work_area':
      case 'location_required':
      case 'already_checked_in':
      case 'unresolved_night_shift':
      case 'late_check_in':
      case 'early_check_in':
      case 'no_active_check_in':
      case 'already_checked_out':
      case 'invalid_shift':
      case 'bad_request':
      case 'server_error':
      case 'unauthorized':
      case 'network_error':
        _showErrorSnackBar(error.message);
        break;
      default:
        _showErrorSnackBar(
          error.message.isNotEmpty 
            ? error.message 
            : 'Check-in failed. Please try again or contact your administrator if the problem persists.',
        );
    }
  }

  Future<void> _checkOut() async {
    // Check if less than 1 hour from check-in and require confirmation
    if (_isLessThanOneHourCheckIn()) {
      final confirmed = await _showConfirmationDialog(
        title: 'Quick Check-out Confirmation',
        message: 'You are checking out less than 1 hour after checking in. Are you sure you want to continue?',
        confirmText: 'Yes, Check Out',
        cancelText: 'Cancel',
      );

      if (!confirmed) {
        return;
      }
    }

    // Check if early check-out and collect reason if needed
    String? earlyCheckoutReason;
    if (_isEarlyCheckOut()) {
      earlyCheckoutReason = await _showReasonDialog(
        title: 'Early Check-out',
        message: 'You are checking out early. Please provide a reason for leaving early.',
        hint: 'e.g., Doctor appointment, family emergency, approved leave...',
      );

      // If user cancelled the dialog, abort check-out
      if (earlyCheckoutReason == null) {
        return;
      }
    }

    setState(() {
      isLoading = true;
    });

    // Debug logging before location check
    if (kDebugMode) {
      debugPrint('DEBUG: Check-out initiated with current state:');
      debugPrint('  currentLocation: $currentLocation');
      debugPrint('  currentPosition: $currentPosition');
      debugPrint('  currentPosition.latitude: ${currentPosition?.latitude}');
      debugPrint('  currentPosition.longitude: ${currentPosition?.longitude}');
    }

    // Ensure we have location data before proceeding
    if (currentLocation == null || currentPosition == null) {
      setState(() {
        isLoading = false;
      });
      if (kDebugMode) {
        debugPrint('DEBUG: Location missing, attempting to refresh...');
      }
      _showErrorSnackBar('Location is required for check-out. Please capture location first.');
      return;
    }

    // Debug logging before API call
    if (kDebugMode) {
      debugPrint('DEBUG: About to call AttendanceController.checkOut with:');
      debugPrint('  location: $currentLocation');
      debugPrint('  latitude: ${currentPosition?.latitude}');
      debugPrint('  longitude: ${currentPosition?.longitude}');
      debugPrint('  earlyCheckoutReason: $earlyCheckoutReason');
    }

    final result = await AttendanceController.checkOut(
      location: currentLocation,
      latitude: currentPosition?.latitude,
      longitude: currentPosition?.longitude,
      earlyCheckoutReason: earlyCheckoutReason,
    );

    setState(() {
      isLoading = false;
    });

    if (result.isSuccess) {
      final data = result.data!;
      _showSuccessSnackBar(
        'Check-out successful for $currentShift. Work hours: ${data['work_hours']}',
      );
      _loadTodayAttendance(); // Refresh data
      return;
    }

    final error = result.error!;
    if (kDebugMode) {
      debugPrint('DEBUG: Check-out error: ${error.code} - ${error.message}');
    }

    switch (error.code) {
      case 'outside_work_area':
      case 'location_required':
      case 'already_checked_in':
      case 'unresolved_night_shift':
      case 'late_check_in':
      case 'early_check_in':
      case 'no_active_check_in':
      case 'already_checked_out':
      case 'invalid_shift':
      case 'bad_request':
      case 'server_error':
      case 'unauthorized':
      case 'network_error':
        _showErrorSnackBar(error.message);
        break;
      default:
        _showErrorSnackBar(
          error.message.isNotEmpty 
            ? error.message 
            : 'Check-out failed. Please try again or contact your administrator if the problem persists.',
        );
    }
  }

  void _showSuccessSnackBar(String message) {
    AppSnackBar.showSuccess(context, message);
  }

  void _showErrorSnackBar(String message) {
    AppSnackBar.showError(context, message);
  }

  /// Check if current time is late for check-in
  bool _isLateCheckIn() {
    final now = DateTime.now();
    final hour = now.hour;
    final minute = now.minute;

    if (currentShift == 'Day Shift') {
      // Late if after 09:00 for day shift
      return hour > dayShiftLateHour || (hour == dayShiftLateHour && minute >= 0);
    } else {
      // Night shift: Late if after 18:00
      return hour >= nightShiftLateHour;
    }
  }

  /// Check if current time is early for check-out
  bool _isEarlyCheckOut() {
    final now = DateTime.now();
    final hour = now.hour;
    final minute = now.minute;

    // Find the most recent active attendance record
    AttendanceRecord? activeAttendance;
    for (final attendance in todayAttendances.reversed) {
      if (attendance.checkInTime != null && attendance.checkOutTime == null) {
        activeAttendance = attendance;
        break;
      }
    }

    if (activeAttendance == null) {
      return false;
    }

    // Get shift type from active attendance
    final shift = activeAttendance.shiftType ?? currentShift;

    if (shift.contains('Day Shift')) {
      // Early if before 16:30 for day shift
      return hour < dayShiftEndHour || (hour == dayShiftEndHour && minute < dayShiftEndMinute);
    } else if (shift.contains('Night Shift')) {
      // Night shift spans midnight
      // Early if before 07:30 (and check-in was after 16:00 previous day)
      if (hour < nightShiftEndHour || (hour == nightShiftEndHour && minute < nightShiftEndMinute)) {
        // Check if this is a valid night shift checkout
        // Night shift: 16:30 - 07:30, so early checkout is before 07:30
        return true;
      }
    }
    return false;
  }

  /// Show dialog to collect reason for late check-in or early check-out
  Future<String?> _showReasonDialog({
    required String title,
    required String message,
    required String hint,
  }) async {
    final controller = TextEditingController();
    String? reason;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildUniformDialog(
        title: title,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: hint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
        primaryAction: ElevatedButton(
          onPressed: () {
            final text = controller.text.trim();
            if (text.isEmpty) {
              AppSnackBar.showError(context, 'Please provide a reason');
              return;
            }
            reason = text;
            Navigator.of(context).pop();
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
          child: const Text('Submit'),
        ),
      ),
    );

    return reason;
  }

  /// Show confirmation dialog for quick check-outs
  Future<bool> _showConfirmationDialog({
    required String title,
    required String message,
    required String confirmText,
    required String cancelText,
  }) async {
    bool confirmed = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildUniformDialog(
        title: title,
        content: Text(message),
        cancelText: cancelText,
        onCancel: () {
          confirmed = false;
        },
        primaryAction: ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            confirmed = true;
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.paleRed,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
          child: Text(confirmText, textAlign: TextAlign.center),
        ),
      ),
    );

    return confirmed;
  }

  /// Check if current check-out is less than 1 hour after check-in
  bool _isLessThanOneHourCheckIn() {
    if (todayAttendances.isEmpty) {
      return false;
    }

    // Find the most recent check-in that hasn't been checked out
    final now = DateTime.now();
    for (final attendance in todayAttendances.reversed) {
      if (attendance.checkInTime != null && attendance.checkOutTime == null) {
        final checkInTime = attendance.checkInTime!;
        final difference = now.difference(checkInTime);

        // For night shifts that span midnight, the difference will naturally be large
        // (e.g., checked in at 4:30 PM yesterday, now 6:00 AM today = ~13.5 hours)
        // So the < 1 hour check will correctly return false for legitimate night shift check-outs
        return difference.inMinutes < 60;
      }
    }

    return false;
  }

  /// Get attendance status color based on current attendances
  Color _getAttendanceStatusColor() {
    if (todayAttendances.isEmpty) {
      return AppTheme.lightGoldAccent;
    }

    // Check if any active check-ins exist
    final hasActiveCheckIn = todayAttendances.any((att) => 
        att.checkInTime != null && att.checkOutTime == null);
    
    if (!hasActiveCheckIn) {
      return AppTheme.lightGoldAccent; // Ready to check in
    }

    // Check if all are checked out
    final allCheckedOut = todayAttendances.every((att) => att.checkOutTime != null);
    
    if (allCheckedOut) {
      return AppTheme.skyBlue.withValues(alpha: 0.8); // Completed for today
    }

    return Colors.yellowAccent; // Currently checked in
  }

  /// Get attendance status text based on current attendances
  String _getAttendanceStatusText() {
    if (todayAttendances.isEmpty) {
      return 'Not checked in yet';
    }

    // Check if any active check-ins exist
    final activeAttendance = todayAttendances.firstWhere(
      (att) => att.checkInTime != null && att.checkOutTime == null,
      orElse: () => todayAttendances.first,
    );

    final hasActiveCheckIn = activeAttendance.checkInTime != null &&
                             activeAttendance.checkOutTime == null;

    if (!hasActiveCheckIn) {
      return 'Ready to check in';
    }

    // Check if this is a night shift check-in from yesterday
    final now = DateTime.now();
    final checkInDate = activeAttendance.checkInTime!;
    final isDifferentDay = checkInDate.day != now.day ||
                           checkInDate.month != now.month ||
                           checkInDate.year != now.year;

    if (isDifferentDay && (activeAttendance.shiftType ?? '').contains('Night Shift')) {
      return 'Night shift from yesterday - pending checkout';
    }

    return 'Currently checked in';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final formattedDate = DateFormat('EEEE, MMMM d, y').format(now);
    final formattedTime = DateFormat('hh:mm:ss a').format(now);

    return Scaffold(
      appBar: const SimpleHeader(
        title: 'Check in & out',
      ),
      body: FloatingNavigation(
        currentIndex: 1, // Attendance is index 1
        onTap: (index) {
          if (index == 1) {
            // Already on attendance screen, do nothing
            return;
          }
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomeScreen(initialIndex: index),
            ),
          );
        },
        child: RefreshIndicator(
          onRefresh: _loadTodayAttendance,
          color: AppTheme.skyBlue,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppTheme.skyBlue,
                              AppTheme.lightGold,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.skyBlue.withValues(alpha: 0.25),
                              blurRadius: 18,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.today_outlined,
                                  color: Colors.white.withValues(alpha: 0.9),
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  formattedDate,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Center(
                              child: Text(
                                formattedTime,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 34,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(
                                  Icons.circle,
                                  size: 10,
                                  color: _getAttendanceStatusColor(),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _getAttendanceStatusText(),
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Shift Information Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: currentShift == 'Day Shift'
                                ? [AppTheme.skyBlue.withValues(alpha: 0.1), AppTheme.skyBlue.withValues(alpha: 0.05)]
                                : [AppTheme.lightGold.withValues(alpha: 0.1), AppTheme.lightGold.withValues(alpha: 0.05)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: currentShift == 'Day Shift' 
                                ? AppTheme.skyBlue.withValues(alpha: 0.2)
                                : AppTheme.lightGold.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: currentShift == 'Day Shift' 
                                        ? AppTheme.skyBlue
                                        : AppTheme.lightGold,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    currentShift == 'Day Shift' ? Icons.wb_sunny : Icons.nightlight,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Current Shift',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                        ),
                                      ),
                                      Text(
                                        currentShift,
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: currentShift == 'Day Shift' 
                                              ? AppTheme.skyBlue
                                              : AppTheme.lightGold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: currentShift == 'Day Shift' 
                                        ? AppTheme.skyBlue.withValues(alpha: 0.1)
                                        : AppTheme.lightGold.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    shiftTimeRange,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: currentShift == 'Day Shift' 
                                          ? AppTheme.skyBlue
                                          : AppTheme.lightGold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Today\'s attendance',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface,
                                  ),
                                ),
                                if (isLoading)
                                  const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (!isLoading && todayAttendances.isEmpty)
                              _buildNoAttendanceStatus()
                            else if (!isLoading && todayAttendances.isNotEmpty)
                              _buildMultipleAttendanceStatus(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Location',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface,
                                  ),
                                ),
                                if (currentLocation != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.skyBlue
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.location_on_outlined,
                                          size: 16,
                                          color: AppTheme.skyBlue,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Captured',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.skyBlue,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (currentLocation != null)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    currentLocation!,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.7),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  if (currentPosition != null)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: SizedBox(
                                        height: 220,
                                        width: double.infinity,
                                        child: FlutterMap(
                                          options: MapOptions(
                                            initialCenter: latlng.LatLng(
                                              currentPosition!.latitude,
                                              currentPosition!.longitude,
                                            ),
                                            initialZoom: 16,
                                          ),
                                          children: [
                                            TileLayer(
                                              urlTemplate:
                                                  'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                                              subdomains: const ['a', 'b', 'c'],
                                              userAgentPackageName:
                                                  'com.hospital.hr.staff_track',
                                            ),
                                            MarkerLayer(
                                              markers: [
                                                Marker(
                                                  point: latlng.LatLng(
                                                    currentPosition!.latitude,
                                                    currentPosition!.longitude,
                                                  ),
                                                  width: 40,
                                                  height: 40,
                                                  child: const Icon(
                                                    Icons.location_on,
                                                    color: AppTheme.paleRedAccent,
                                                    size: 40,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  if (currentPosition == null)
                                    Text(
                                      'Current coordinates not available. Please refresh location.',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.6),
                                      ),
                                    ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed:
                                          isGettingLocation ? null : _getCurrentLocation,
                                      icon: isGettingLocation
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Icon(Icons.refresh),
                                      label: Text(
                                        isGettingLocation
                                            ? 'Updating location...'
                                            : 'Update location',
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            else
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Capture your current location for more accurate attendance records.',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.7),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed:
                                          isGettingLocation ? null : _getCurrentLocation,
                                      icon: isGettingLocation
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Icon(Icons.location_on_outlined),
                                      label: Text(
                                        isGettingLocation
                                            ? 'Getting location...'
                                            : 'Get current location',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: Builder(
                          builder: (context) {
                            final hasLocation =
                                currentLocation != null && currentPosition != null;
                            

                            
                            // Check if user has any active check-ins (not checked out)
                            final hasActiveCheckIn = todayAttendances.any((att) => 
                                att.checkInTime != null && att.checkOutTime == null);
                            
                            if (!hasActiveCheckIn) {
                              return ElevatedButton.icon(
                                onPressed:
                                    isLoading || !hasLocation ? null : _checkIn,
                                icon: const Icon(Icons.login),
                                label: const Text('Check in'),
                              );
                            } else {
                              return ElevatedButton.icon(
                                onPressed:
                                    isLoading || !hasLocation ? null : _checkOut,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.paleRed,
                                  foregroundColor: Colors.white,
                                ),
                                icon: const Icon(Icons.logout),
                                label: const Text('Check out'),
                              );
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppTheme.skyBlue.withValues(alpha: 0.05),
                              AppTheme.lightGold.withValues(alpha: 0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppTheme.skyBlue.withValues(alpha: 0.1),
                            width: 1,
                          ),
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const AttendanceHistoryScreen(),
                              ),
                            );
                          },
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.skyBlue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.history_outlined,
                              color: AppTheme.skyBlue,
                              size: 20,
                            ),
                          ),
                          label: Column(
                            children: [
                              const Text(
                                'View Attendance History',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.skyBlue,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Check your complete attendance records',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: AppTheme.skyBlue,
                            elevation: 0,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
    ),
      );
  }

  Widget _buildNoAttendanceStatus() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.skyBlue.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.skyBlue.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.skyBlue.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.info_outline,
              color: AppTheme.skyBlue,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No attendance yet',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ready to check in for $currentShift ($shiftTimeRange)',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textGrey.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMultipleAttendanceStatus() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: todayAttendances.map((attendance) => 
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildAttendanceStatus(attendance),
        )
      ).toList(),
    );
  }

  Widget _buildAttendanceStatus(AttendanceRecord attendance) {
    final attendanceShift = attendance.shiftType ?? 'Unknown Shift';
    final isCurrentShift = attendanceShift == currentShift;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Shift information row
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isCurrentShift 
                ? AppTheme.skyBlue.withValues(alpha: 0.1)
                : AppTheme.lightGold.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isCurrentShift 
                  ? AppTheme.skyBlue.withValues(alpha: 0.3)
                  : AppTheme.lightGold.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                attendanceShift == 'Day Shift' ? Icons.wb_sunny : Icons.nightlight,
                size: 16,
                color: isCurrentShift ? AppTheme.skyBlue : AppTheme.lightGold,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$attendanceShift (${ShiftUtils.getShiftTimeRange(attendanceShift)})',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isCurrentShift ? AppTheme.skyBlue : AppTheme.lightGold,
                  ),
                ),
              ),
              if (!isCurrentShift)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.paleRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Different shift',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppTheme.paleRed,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildStatusRow(
          'Status',
          _getAttendanceStatus(attendance),
          Icons.info,
          _getStatusColor(_getAttendanceStatus(attendance)),
        ),
        if (attendance.checkInTime != null) ...[
          const SizedBox(height: 8),
          _buildStatusRow(
            'Check In',
            DateFormat('h:mm a').format(attendance.checkInTime!),
            Icons.login,
            AppTheme.skyBlue,
          ),
          if (attendance.location != null) ...[
            const SizedBox(height: 4),
            Text(
              'Location: ${attendance.location}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ],
        if (attendance.checkOutTime != null) ...[
          const SizedBox(height: 8),
          _buildStatusRow(
            'Check Out',
            DateFormat('h:mm a').format(attendance.checkOutTime!),
            Icons.logout,
            AppTheme.paleRed,
          ),
          if (attendance.location != null) ...[
            const SizedBox(height: 4),
            Text(
              'Location: ${attendance.location}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ],
        if (attendance.workHours != null) ...[
          const SizedBox(height: 8),
          _buildStatusRow(
            'Work Hours',
            '${attendance.workHours!.toStringAsFixed(2)} hours',
            Icons.schedule,
            AppTheme.lightGold,
          ),
        ],
      ],
    );

}

  Widget _buildStatusRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return AppTheme.skyBlue;
      case 'late':
        return AppTheme.lightGold;
      case 'absent':
        return AppTheme.paleRed;
      case 'half_day':
        return AppTheme.lightGold;
      default:
        return Colors.grey;
    }
  }

  String _getAttendanceStatus(AttendanceRecord attendance) {
    if (!attendance.isCheckedIn) {
      return 'NOT CHECKED IN';
    } else if (!attendance.isCheckedOut) {
      return 'CHECKED IN';
    } else {
      return 'COMPLETE';
    }
  }
}
