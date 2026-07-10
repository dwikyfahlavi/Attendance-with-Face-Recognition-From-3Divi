import 'package:package_info_plus/package_info_plus.dart';

/// Application configuration and version management
/// Version is defined once in pubspec.yaml (version: 1.0.0+1)
/// This class reads the version info from the built package at runtime
class AppConfig {
  static PackageInfo? _packageInfo;

  /// Initialize app configuration (call once on app startup)
  static Future<void> initialize() async {
    _packageInfo = await PackageInfo.fromPlatform();
  }

  /// Get app version from build config (e.g., "1.0.0")
  static String get appVersion {
    return _packageInfo?.version ?? '1.0.3';
  }

  /// Get build number from build config (e.g., "1")
  static String get buildNumber {
    return _packageInfo?.buildNumber ?? '1';
  }

  /// Get full version string (e.g., "1.0.0 (Build 1)")
  static String get fullVersion {
    return '$appVersion (Build $buildNumber)';
  }

  /// Get app name
  static String get appName {
    return _packageInfo?.appName ?? 'Attendance System';
  }
}
