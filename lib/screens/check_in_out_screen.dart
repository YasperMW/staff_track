import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import '../controllers/attendance_controller.dart';
import '../models/models.dart';
import 'attendance_history_screen.dart';

class CheckInOutScreen extends StatefulWidget {
  const CheckInOutScreen({Key? key}) : super(key: key);

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

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        currentPosition = position;
        currentLocation = 'Lat: ${position.latitude.toStringAsFixed(6)}, Lng: ${position.longitude.toStringAsFixed(6)}';
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
      appBar: AppBar(
        title: const Text('Check In/Out'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _loadTodayAttendance,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Date and Time Card
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        formattedDate,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        formattedTime,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.blue[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Today's Attendance Status
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Today\'s Attendance',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      if (isLoading)
                        const Center(child: CircularProgressIndicator())
                      else if (todayAttendance == null)
                        _buildNoAttendanceStatus()
                      else
                        _buildAttendanceStatus(todayAttendance!),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Location Card
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Location',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      if (currentLocation != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentLocation!,
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: _getCurrentLocation,
                              icon: isGettingLocation
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.refresh),
                              label: Text(isGettingLocation ? 'Getting Location...' : 'Update Location'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        )
                      else
                        ElevatedButton.icon(
                          onPressed: _getCurrentLocation,
                          icon: isGettingLocation
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.location_on),
                          label: Text(isGettingLocation ? 'Getting Location...' : 'Get Current Location'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[600],
                            foregroundColor: Colors.white,
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Action Buttons
              if (todayAttendance == null || !todayAttendance!.isCheckedIn)
                ElevatedButton(
                  onPressed: isLoading ? null : _checkIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.login, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'CHECK IN',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              else if (todayAttendance!.isCheckedIn && !todayAttendance!.isCheckedOut)
                ElevatedButton(
                  onPressed: isLoading ? null : _checkOut,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.logout, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'CHECK OUT',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Card(
                  color: Colors.grey[100],
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.green[600],
                          size: 48,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Already checked out for today',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 20),

              // View History Button
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AttendanceHistoryScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.history),
                label: const Text('View Attendance History'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
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
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.orange[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'No attendance record for today. Please check in to start your day.',
              style: TextStyle(color: Colors.orange[700]),
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
