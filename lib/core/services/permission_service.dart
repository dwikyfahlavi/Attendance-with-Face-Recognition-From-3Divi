import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /// Request camera permission from the user
  /// Returns true if permission granted, false otherwise
  static Future<bool> requestCameraPermission() async {
    try {
      final status = await Permission.camera.request();
      return status.isGranted;
    } catch (e) {
      return false;
    }
  }

  /// Check if camera permission is already granted
  static Future<bool> isCameraPermissionGranted() async {
    try {
      final status = await Permission.camera.status;
      return status.isGranted;
    } catch (e) {
      return false;
    }
  }

  /// Open app settings if permission is denied
  static Future<void> openAppSettings() async {
    try {
      await openAppSettings();
    } catch (e) {
      // Silently fail
    }
  }

  /// Request multiple permissions at once
  static Future<Map<Permission, PermissionStatus>> requestPermissions(
    List<Permission> permissions,
  ) async {
    try {
      return await permissions.request();
    } catch (e) {
      return {};
    }
  }
}
