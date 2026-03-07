import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../controllers/attendance_controller.dart';
import '../../controllers/auth_provider.dart';
import '../../models/models.dart';
import '../../widgets/floating_navigation.dart';
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
  String currentShift = '';
  String shiftTimeRange = '';

  @override
  void initState() {
    super.initState();
    _updateShiftInfo();
    _loadTodayAttendance();
    _getCurrentLocation();
    
    // Update time and shift info every second
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        _updateShiftInfo();
        setState(() {}); // Trigger rebuild to update time
      }
    });
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
    print('DEBUG: Starting location capture...');
    setState(() {
      isGettingLocation = true;
    });

    try {
      // Check if location services are enabled
      print('DEBUG: Checking if location services are enabled...');
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      print('DEBUG: Location services enabled: $serviceEnabled');
      
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }

      // Check location permissions using permission service
      print('DEBUG: Checking location permissions...');
      bool hasPermission = await PermissionService.requestLocationPermission();
      print('DEBUG: Location permission granted: $hasPermission');
      
      if (!hasPermission) {
        throw Exception('Location permissions are required for check-in/out');
      }

      // Get current position
      print('DEBUG: Getting current position...');
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      print('DEBUG: Position obtained:');
      print('  Latitude: ${position.latitude}');
      print('  Longitude: ${position.longitude}');
      print('  Accuracy: ${position.accuracy} meters');

      String locationText =
          'Lat: ${position.latitude.toStringAsFixed(6)}, Lng: ${position.longitude.toStringAsFixed(6)}';

      try {
        print('DEBUG: Getting address from coordinates...');
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        print('DEBUG: Found ${placemarks.length} placemarks');
        
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          print('DEBUG: Primary placemark: ${place.name}, ${place.locality}, ${place.subAdministrativeArea}');
          
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
            print('DEBUG: Formatted location text: $locationText');
          }
        }
      } catch (e) {
        print('DEBUG: Failed to get address: $e');
      }

      print('DEBUG: Setting location state...');
      setState(() {
        currentPosition = position;
        currentLocation = locationText;
        isGettingLocation = false;
      });
      
      print('DEBUG: Location capture completed successfully');
      print('  Final currentLocation: $currentLocation');
      print('  Final currentPosition: $currentPosition');
      
    } catch (e) {
      print('DEBUG: Location capture failed: $e');
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

    // Debug logging before location check
    print('DEBUG: Check-in initiated with current state:');
    print('  currentLocation: $currentLocation');
    print('  currentPosition: $currentPosition');
    print('  currentPosition.latitude: ${currentPosition?.latitude}');
    print('  currentPosition.longitude: ${currentPosition?.longitude}');

    // Ensure we have location data before proceeding
    if (currentLocation == null || currentPosition == null) {
      setState(() {
        isLoading = false;
      });
      print('DEBUG: Location missing, attempting to refresh...');
      _showErrorSnackBar('Location is required for check-in. Please capture location first.');
      return;
    }

    // Debug logging before API call
    print('DEBUG: About to call AttendanceController.checkIn with:');
    print('  location: $currentLocation');
    print('  latitude: ${currentPosition?.latitude}');
    print('  longitude: ${currentPosition?.longitude}');
    print('  currentShift: $currentShift');

    try {
      final result = await AttendanceController.checkIn(
        location: currentLocation,
        latitude: currentPosition?.latitude,
        longitude: currentPosition?.longitude,
        shiftType: currentShift, // Store current shift
      );

      setState(() {
        isLoading = false;
      });

      _showSuccessSnackBar('Check-in successful for $currentShift at ${result['check_in_time']}');
      _loadTodayAttendance(); // Refresh data
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      
      // Provide user-friendly error messages
      String errorMessage = e.toString();
      print('DEBUG: Check-in error: $errorMessage');
      
      if (errorMessage.contains('Outside allowed work area')) {
        _showErrorSnackBar(
          'You are currently outside the allowed work area. '
          'Please move closer to your workplace and try again.',
        );
      } else if (errorMessage.contains('Location data is required')) {
        _showErrorSnackBar('Location is required for check-in. Please ensure location services are enabled and try again.');
      } else if (errorMessage.contains('location') || errorMessage.contains('Location')) {
        _showErrorSnackBar('Location error occurred. Please check your location services and try again.');
      } else {
        _showErrorSnackBar('Check-in failed. Please try again or contact your administrator if the problem persists.');
      }
    }
  }

  Future<void> _checkOut() async {
    setState(() {
      isLoading = true;
    });

    // Debug logging before location check
    print('DEBUG: Check-out initiated with current state:');
    print('  currentLocation: $currentLocation');
    print('  currentPosition: $currentPosition');
    print('  currentPosition.latitude: ${currentPosition?.latitude}');
    print('  currentPosition.longitude: ${currentPosition?.longitude}');

    // Ensure we have location data before proceeding
    if (currentLocation == null || currentPosition == null) {
      setState(() {
        isLoading = false;
      });
      print('DEBUG: Location missing, attempting to refresh...');
      _showErrorSnackBar('Location is required for check-out. Please capture location first.');
      return;
    }

    // Debug logging before API call
    print('DEBUG: About to call AttendanceController.checkOut with:');
    print('  location: $currentLocation');
    print('  latitude: ${currentPosition?.latitude}');
    print('  longitude: ${currentPosition?.longitude}');

    try {
      final result = await AttendanceController.checkOut(
        location: currentLocation,
        latitude: currentPosition?.latitude,
        longitude: currentPosition?.longitude,
      );

      setState(() {
        isLoading = false;
      });

      _showSuccessSnackBar('Check-out successful for $currentShift. Work hours: ${result['work_hours']}');
      _loadTodayAttendance(); // Refresh data
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      
      // Provide user-friendly error messages
      String errorMessage = e.toString();
      print('DEBUG: Check-out error: $errorMessage');
      
      if (errorMessage.contains('Outside allowed work area')) {
        _showErrorSnackBar(
          'You are currently outside the allowed work area. '
          'Please move closer to your workplace and try again.',
        );
      } else if (errorMessage.contains('Location data is required')) {
        _showErrorSnackBar('Location is required for check-out. Please ensure location services are enabled and try again.');
      } else if (errorMessage.contains('location') || errorMessage.contains('Location')) {
        _showErrorSnackBar('Location error occurred. Please check your location services and try again.');
      } else {
        _showErrorSnackBar('Check-out failed. Please try again or contact your administrator if the problem persists.');
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.skyBlue,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.paleRed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final formattedDate = DateFormat('EEEE, MMMM d, y').format(now);
    final formattedTime = DateFormat('hh:mm:ss a').format(now);

    return FloatingNavigation(
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
                                  color: todayAttendance == null ||
                                          !todayAttendance!.isCheckedIn
                                      ? AppTheme.lightGoldAccent
                                      : todayAttendance!.isCheckedOut
                                          ? AppTheme.skyBlue.withValues(alpha: 0.8)
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
                            
                            // Debug logging
                            print('DEBUG: Button state check:');
                            print('  currentLocation: $currentLocation');
                            print('  currentPosition: $currentPosition');
                            print('  hasLocation: $hasLocation');
                            print('  isLoading: $isLoading');
                            
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
                                  backgroundColor: AppTheme.paleRed,
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
                                  color: AppTheme.lightGold,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      color: AppTheme.skyBlue,
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
        selectedItemColor: AppTheme.skyBlue,
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
              color: AppTheme.skyBlue,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        const SizedBox(height: 4),
        Icon(isActive ? activeIcon : inactiveIcon),
      ],
    );
  }
}
