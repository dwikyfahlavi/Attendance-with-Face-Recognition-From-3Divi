import 'package:hive/hive.dart';
import '../models/settings_model.dart';

class SettingsRepository {
  final Box<SettingsModel> _settingsBox;
  static const String _defaultKey = 'settings';

  SettingsRepository(this._settingsBox);

  /// Get current settings, return default if not found
  Future<SettingsModel> getSettings() async {
    try {
      final settings = _settingsBox.get(_defaultKey);
      if (settings != null) {
        return settings;
      }
      // Return default settings if none exist
      return SettingsModel(lastUpdated: DateTime.now());
    } catch (e) {
      return SettingsModel(lastUpdated: DateTime.now());
    }
  }

  /// Save/update settings
  Future<void> saveSettings({
    required int checkInHour,
    required int checkInMinute,
    required int checkOutHour,
    required int checkOutMinute,
    String? updatedBy,
    bool? faceRecognitionEnabled,
    String? baseProtocol,
    String? ipPort,
    String? apiPath,
    String? userId,
    String? employeeCode,
    String? employeeName,
    String? attendanceCode,
    String? unattendanceCode,
  }) async {
    try {
      final current = await getSettings();
      final settings = SettingsModel(
        checkInHour: checkInHour,
        checkInMinute: checkInMinute,
        checkOutHour: checkOutHour,
        checkOutMinute: checkOutMinute,
        lastUpdated: DateTime.now(),
        updatedBy: updatedBy,
        faceRecognitionEnabled:
            faceRecognitionEnabled ?? current.faceRecognitionEnabled,
        baseProtocol: baseProtocol ?? current.baseProtocol,
        ipPort: ipPort ?? current.ipPort,
        apiPath: apiPath ?? current.apiPath,
        userId: userId ?? current.userId,
        employeeCode: employeeCode ?? current.employeeCode,
        employeeName: employeeName ?? current.employeeName,
        attendanceCode: attendanceCode ?? current.attendanceCode,
        unattendanceCode: unattendanceCode ?? current.unattendanceCode,
      );
      await _settingsBox.put(_defaultKey, settings);
    } catch (e) {
      throw Exception('Failed to save settings: $e');
    }
  }

  /// Update check-in/out hours only
  Future<void> setCheckInOutHours(
    int checkInHour,
    int checkInMinute,
    int checkOutHour,
    int checkOutMinute,
  ) async {
    try {
      final current = await getSettings();
      await saveSettings(
        checkInHour: checkInHour,
        checkInMinute: checkInMinute,
        checkOutHour: checkOutHour,
        checkOutMinute: checkOutMinute,
        updatedBy: current.updatedBy,
        baseProtocol: current.baseProtocol,
        ipPort: current.ipPort,
        apiPath: current.apiPath,
      );
    } catch (e) {
      throw Exception('Failed to update check-in/out hours: $e');
    }
  }

  /// Check if a given time is late
  Future<bool> isLateTime(DateTime dateTime, String type) async {
    try {
      final settings = await getSettings();
      return settings.isLateTime(dateTime, type);
    } catch (e) {
      // Default to 9:00 AM for check-ins
      return type == 'CheckIn' &&
          (dateTime.hour > 9 || (dateTime.hour == 9 && dateTime.minute > 0));
    }
  }

  /// Get face recognition enabled status
  Future<bool> isFaceRecognitionEnabled() async {
    try {
      final settings = await getSettings();
      return settings.faceRecognitionEnabled;
    } catch (e) {
      return true; // Default to enabled
    }
  }

  /// Set face recognition enabled status
  Future<void> setFaceRecognitionEnabled(bool enabled) async {
    try {
      final current = await getSettings();
      await saveSettings(
        checkInHour: current.checkInHour,
        checkInMinute: current.checkInMinute,
        checkOutHour: current.checkOutHour,
        checkOutMinute: current.checkOutMinute,
        updatedBy: current.updatedBy,
        faceRecognitionEnabled: enabled,
        baseProtocol: current.baseProtocol,
        ipPort: current.ipPort,
        apiPath: current.apiPath,
      );
    } catch (e) {
      throw Exception('Failed to update face recognition setting: $e');
    }
  }

  /// Reset to default settings
  Future<void> resetToDefaults() async {
    try {
      await _settingsBox.delete(_defaultKey);
    } catch (e) {
      throw Exception('Failed to reset settings: $e');
    }
  }

  Future<void> setApiConfig({
    required String ipPort,
    String? baseProtocol,
    String? apiPath,
  }) async {
    try {
      final current = await getSettings();
      await saveSettings(
        checkInHour: current.checkInHour,
        checkInMinute: current.checkInMinute,
        checkOutHour: current.checkOutHour,
        checkOutMinute: current.checkOutMinute,
        updatedBy: current.updatedBy,
        faceRecognitionEnabled: current.faceRecognitionEnabled,
        baseProtocol: baseProtocol ?? current.baseProtocol,
        ipPort: ipPort,
        apiPath: apiPath ?? current.apiPath,
      );
    } catch (e) {
      throw Exception('Failed to update API config: $e');
    }
  }

  Future<void> setCurrentEmployeeAndAttendanceCode(
    String employeeCode,
    String employeeName,
    String userId,
    String attendanceCode,
    String unattendanceCode,
  ) async {
    try {
      final current = await getSettings();
      await saveSettings(
        checkInHour: current.checkInHour,
        checkInMinute: current.checkInMinute,
        checkOutHour: current.checkOutHour,
        checkOutMinute: current.checkOutMinute,
        updatedBy: current.updatedBy,
        faceRecognitionEnabled: current.faceRecognitionEnabled,
        baseProtocol: current.baseProtocol,
        ipPort: current.ipPort,
        apiPath: current.apiPath,
        employeeCode: employeeCode,
        employeeName: employeeName,
        userId: userId,
        attendanceCode: attendanceCode,
        unattendanceCode: unattendanceCode,
      );
    } catch (e) {
      throw Exception('Failed to update current employee: $e');
    }
  }
}
