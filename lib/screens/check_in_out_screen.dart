import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../controllers/attendance_controller.dart';
import '../controllers/auth_provider.dart';
import '../models/models.dart';
import '../widgets/app_header.dart';
import '../services/permission_service.dart';
import 'attendance_history_screen.dart';
import 'home_screen.dart';

class CheckInOutScreen extends StatefulWidget {
  const CheckInOutScreen({super.key});

  @override
  State<CheckInOutScreen> createState() => _CheckInOutScreenState();
}

class _CheckInOutScreenState extends State<CheckInOutScreen> {
  AttendanceRecord? todayAttendance;
  bool isLoading = false;
  bool isGettingLocation = false;
  String? currentLocation;
  Position? currentPosition;

  @override
  void initState() {
    super.initState();
    _loadTodayAttendance();
    _getCurrentLocation();
  }

  Future<void> _loadTodayAttendance() async {
    setState(() {
      isLoading = true;
    });

    try {
      final attendance = await AttendanceController.getTodayAttendance();
      setState(() {
        todayAttendance = attendance;
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
    setState(() {
      isGettingLocation = true;
    });

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }

      // Check location permissions using permission service
      bool hasPermission = await PermissionService.requestLocationPermission();
      if (!hasPermission) {
        throw Exception('Location permissions are required for check-in/out');
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      String locationText =
          'Lat: ${position.latitude.toStringAsFixed(6)}, Lng: ${position.longitude.toStringAsFixed(6)}';

      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
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
          }
        }
      } catch (_) {}

      setState(() {
        currentPosition = position;
        currentLocation = locationText;
        isGettingLocation = false;
      });
    } catch (e) {
      setState(() {
        isGettingLocation = false;
      });
      _showErrorSnackBar('Failed to get location: $e');
    }
  }

  Future<void> _checkIn() async {
    setState(() {
      isLoading = true;
    });

    try {
      final result = await AttendanceController.checkIn(
        location: currentLocation,
        latitude: currentPosition?.latitude,
        longitude: currentPosition?.longitude,
      );

      setState(() {
        isLoading = false;
      });

      _showSuccessSnackBar('Check-in successful at ${result['check_in_time']}');
      _loadTodayAttendance(); // Refresh data
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showErrorSnackBar('Check-in failed: $e');
    }
  }

  Future<void> _checkOut() async {
    setState(() {
      isLoading = true;
    });

    try {
      final result = await AttendanceController.checkOut(
        location: currentLocation,
        latitude: currentPosition?.latitude,
        longitude: currentPosition?.longitude,
      );

      setState(() {
        isLoading = false;
      });

      _showSuccessSnackBar('Check-out successful. Work hours: ${result['work_hours']}');
      _loadTodayAttendance(); // Refresh data
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showErrorSnackBar('Check-out failed: $e');
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final formattedDate = DateFormat('EEEE, MMMM d, y').format(now);
    final formattedTime = DateFormat('h:mm a').format(now);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadTodayAttendance,
          color: AppTheme.primaryBlue,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppHeader(
                  subtitle: 'Attendance',
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      Text(
                        'Check in & out',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Manage today\'s time and location in one place.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppTheme.primaryBlue,
                              Color(0xFF5D8BF4),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryBlue.withValues(alpha: 0.25),
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
                            Text(
                              formattedTime,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 34,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(
                                  Icons.circle,
                                  size: 10,
                                  color: todayAttendance == null ||
                                          !todayAttendance!.isCheckedIn
                                      ? Colors.orangeAccent
                                      : todayAttendance!.isCheckedOut
                                          ? Colors.greenAccent
                                          : Colors.yellowAccent,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  todayAttendance == null
                                      ? 'Not checked in yet'
                                      : !todayAttendance!.isCheckedIn
                                          ? 'Ready to check in'
                                          : todayAttendance!.isCheckedOut
                                              ? 'Completed for today'
                                              : 'Currently checked in',
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
                            if (!isLoading && todayAttendance == null)
                              _buildNoAttendanceStatus()
                            else if (!isLoading && todayAttendance != null)
                              _buildAttendanceStatus(todayAttendance!),
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
                                      color: AppTheme.primaryBlue
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.location_on_outlined,
                                          size: 16,
                                          color: AppTheme.primaryBlue,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Captured',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.primaryBlue,
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
                                                    color: Colors.redAccent,
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
                            if (todayAttendance == null ||
                                !todayAttendance!.isCheckedIn) {
                              return ElevatedButton.icon(
                                onPressed:
                                    isLoading || !hasLocation ? null : _checkIn,
                                icon: const Icon(Icons.login),
                                label: const Text('Check in'),
                              );
                            } else if (todayAttendance!.isCheckedIn &&
                                !todayAttendance!.isCheckedOut) {
                              return ElevatedButton.icon(
                                onPressed:
                                    isLoading || !hasLocation ? null : _checkOut,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                                icon: const Icon(Icons.logout),
                                label: const Text('Check out'),
                              );
                            } else {
                              return Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppTheme.accentTeal,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      color: Colors.green[700],
                                      size: 32,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'All done for today',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'You have already checked out. See your history for details.',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withValues(alpha: 0.7),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const AttendanceHistoryScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.history),
                        label: const Text('View attendance history'),
                        style: OutlinedButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
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
      bottomNavigationBar: const _CheckInOutBottomNavigation(),
    );
  }

  Widget _buildNoAttendanceStatus() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryBlue.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.info_outline,
              color: AppTheme.primaryBlue,
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
                  'Tap Check in to start tracking your working hours for today.',
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

  Widget _buildAttendanceStatus(AttendanceRecord attendance) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
            Colors.green,
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
            Colors.red,
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
            Colors.blue,
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
        return Colors.green;
      case 'late':
        return Colors.orange;
      case 'absent':
        return Colors.red;
      case 'half_day':
        return Colors.blue;
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

class _CheckInOutBottomNavigation extends StatelessWidget {
  const _CheckInOutBottomNavigation();

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null) return const SizedBox.shrink();

    final isAdmin = user.role.toLowerCase().contains('admin') ||
        user.role.toLowerCase().contains('hr') ||
        user.role.toLowerCase().contains('manager');

    const currentIndex = 1;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.grey.withValues(alpha: 0.2),
            width: 0.5,
          ),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => HomeScreen(initialIndex: index),
            ),
            (route) => false,
          );
        },
        selectedItemColor: AppTheme.primaryBlue,
        unselectedItemColor: Theme.of(context)
            .colorScheme
            .onSurface
            .withValues(alpha: 0.4),
        selectedFontSize: 12,
        unselectedFontSize: 12,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        items: [
          BottomNavigationBarItem(
            icon: _buildNavIcon(
              context,
              0,
              isAdmin ? Icons.dashboard : Icons.home,
              isAdmin ? Icons.dashboard_outlined : Icons.home_outlined,
              currentIndex,
            ),
            label: isAdmin ? 'Dashboard' : 'Home',
          ),
          BottomNavigationBarItem(
            icon: _buildNavIcon(
              context,
              1,
              Icons.access_time,
              Icons.access_time_outlined,
              currentIndex,
            ),
            label: 'Attendance',
          ),
          BottomNavigationBarItem(
            icon: _buildNavIcon(
              context,
              2,
              isAdmin ? Icons.assignment_turned_in : Icons.bar_chart,
              isAdmin
                  ? Icons.assignment_turned_in_outlined
                  : Icons.bar_chart_outlined,
              currentIndex,
            ),
            label: isAdmin ? 'Requests' : 'Reports',
          ),
          BottomNavigationBarItem(
            icon: _buildNavIcon(
              context,
              3,
              isAdmin ? Icons.analytics : Icons.description,
              isAdmin ? Icons.analytics_outlined : Icons.description_outlined,
              currentIndex,
            ),
            label: isAdmin ? 'Analytics' : 'Requests',
          ),
        ],
      ),
    );
  }

  Widget _buildNavIcon(
    BuildContext context,
    int index,
    IconData activeIcon,
    IconData inactiveIcon,
    int currentIndex,
  ) {
    final isActive = currentIndex == index;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isActive)
          Container(
            width: 24,
            height: 2,
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        const SizedBox(height: 4),
        Icon(isActive ? activeIcon : inactiveIcon),
      ],
    );
  }
}
