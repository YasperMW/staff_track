import 'package:geolocator/geolocator.dart';
 import 'package:permission_handler/permission_handler.dart' as ph;

class PermissionService {
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
      print('Error requesting location permission: $e');
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
      print('Error requesting camera permission: $e');
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
      print('Error requesting storage permission: $e');
      return false;
    }
  }

  static Future<LocationPermission> checkLocationPermission() async {
    try {
      return await Geolocator.checkPermission();
    } catch (e) {
      print('Error checking location permission: $e');
      return LocationPermission.denied;
    }
  }

  static Future<ph.PermissionStatus> checkCameraPermission() async {
    try {
      return await ph.Permission.camera.status;
    } catch (e) {
      print('Error checking camera permission: $e');
      return ph.PermissionStatus.denied;
    }
  }

  static Future<ph.PermissionStatus> checkStoragePermission() async {
    try {
      return await ph.Permission.storage.status;
    } catch (e) {
      print('Error checking storage permission: $e');
      return ph.PermissionStatus.denied;
    }
  }

  static Future<void> openAppSettings() async {
    try {
      await ph.openAppSettings();
    } catch (e) {
      print('Error opening app settings: $e');
    }
  }

  static Future<bool> hasLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      return permission == LocationPermission.always || 
             permission == LocationPermission.whileInUse;
    } catch (e) {
      print('Error checking location permission: $e');
      return false;
    }
  }

  static Future<bool> hasCameraPermission() async {
    try {
      var status = await ph.Permission.camera.status;
      return status.isGranted;
    } catch (e) {
      print('Error checking camera permission: $e');
      return false;
    }
  }

  static Future<bool> hasStoragePermission() async {
    try {
      var status = await ph.Permission.storage.status;
      return status.isGranted;
    } catch (e) {
      print('Error checking storage permission: $e');
      return false;
    }
  }
}
