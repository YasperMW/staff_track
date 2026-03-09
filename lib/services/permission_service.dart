import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

enum LocationAccessState {
  ready,
  servicesDisabled,
  permissionDenied,
  permissionPermanentlyDenied,
  error,
}

class LocationAccessResult {
  final LocationAccessState state;
  final String message;

  const LocationAccessResult({
    required this.state,
    required this.message,
  });
}

class PermissionService {
  static Future<LocationAccessResult> getLocationAccessStatus() async {
    try {
      // Check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const LocationAccessResult(
          state: LocationAccessState.servicesDisabled,
          message:
              'Location services are disabled. Please enable them in settings and try again.',
        );
      }

      // Check and request location permissions
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        return const LocationAccessResult(
          state: LocationAccessState.permissionPermanentlyDenied,
          message:
              'Location permission is permanently denied. Please enable it from app settings.',
        );
      }

      if (permission == LocationPermission.denied) {
        return const LocationAccessResult(
          state: LocationAccessState.permissionDenied,
          message:
              'Location permission is required. Please allow access and try again.',
        );
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        return const LocationAccessResult(
          state: LocationAccessState.ready,
          message: 'Location ready.',
        );
      }

      return const LocationAccessResult(
        state: LocationAccessState.error,
        message: 'Unexpected location permission state.',
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error determining location access status: $e');
      }
      return const LocationAccessResult(
        state: LocationAccessState.error,
        message:
            'Unable to determine location access. Please check settings and try again.',
      );
    }
  }

  static Future<bool> requestLocationPermission() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Location services are disabled. Ask user to enable them
        serviceEnabled = await Geolocator.openLocationSettings();
        return serviceEnabled;
      }

      // Check and request location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      return permission == LocationPermission.whileInUse ||
             permission == LocationPermission.always;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error requesting location permission: $e');
      }
      return false;
    }
  }

  static Future<bool> requestCameraPermission() async {
    try {
      var status = await ph.Permission.camera.status;
      
      if (status.isDenied) {
        status = await ph.Permission.camera.request();
      }

      return status.isGranted;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error requesting camera permission: $e');
      }
      return false;
    }
  }

  static Future<bool> requestStoragePermission() async {
    try {
      var status = await ph.Permission.storage.status;
      
      if (status.isDenied) {
        status = await ph.Permission.storage.request();
      }

      return status.isGranted;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error requesting storage permission: $e');
      }
      return false;
    }
  }

  static Future<LocationPermission> checkLocationPermission() async {
    try {
      return await Geolocator.checkPermission();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error checking location permission: $e');
      }
      return LocationPermission.denied;
    }
  }

  static Future<ph.PermissionStatus> checkCameraPermission() async {
    try {
      return await ph.Permission.camera.status;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error checking camera permission: $e');
      }
      return ph.PermissionStatus.denied;
    }
  }

  static Future<ph.PermissionStatus> checkStoragePermission() async {
    try {
      return await ph.Permission.storage.status;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error checking storage permission: $e');
      }
      return ph.PermissionStatus.denied;
    }
  }

  static Future<void> openAppSettings() async {
    try {
      await ph.openAppSettings();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error opening app settings: $e');
      }
    }
  }

  static Future<bool> hasLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      return permission == LocationPermission.always || 
             permission == LocationPermission.whileInUse;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking location permission: $e');
      }
      return false;
    }
  }

  static Future<bool> hasCameraPermission() async {
    try {
      var status = await ph.Permission.camera.status;
      return status.isGranted;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking camera permission: $e');
      }
      return false;
    }
  }

  static Future<bool> hasStoragePermission() async {
    try {
      var status = await ph.Permission.storage.status;
      return status.isGranted;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking storage permission: $e');
      }
      return false;
    }
  }
}
