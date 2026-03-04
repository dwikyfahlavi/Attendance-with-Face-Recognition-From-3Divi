import 'package:hive/hive.dart';
import '../../../models/settings_model.dart';

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
    required int lateHour,
    required int lateMinute,
    String? updatedBy,
    bool? faceRecognitionEnabled,
    String? baseProtocol,
    String? ipPort,
    String? apiPath,
    String? employeeCode,
    String? employeeName,
  }) async {
    try {
      final current = await getSettings();
      final settings = SettingsModel(
        lateHour: lateHour,
        lateMinute: lateMinute,
        lastUpdated: DateTime.now(),
        updatedBy: updatedBy,
        faceRecognitionEnabled:
            faceRecognitionEnabled ?? current.faceRecognitionEnabled,
        baseProtocol: baseProtocol ?? current.baseProtocol,
        ipPort: ipPort ?? current.ipPort,
        apiPath: apiPath ?? current.apiPath,
        employeeCode: employeeCode ?? current.employeeCode,
        employeeName: employeeName ?? current.employeeName,
      );
      await _settingsBox.put(_defaultKey, settings);
    } catch (e) {
      throw Exception('Failed to save settings: $e');
    }
  }

  /// Update late hour only
  Future<void> setLateHour(int hour, int minute) async {
    try {
      final current = await getSettings();
      await saveSettings(
        lateHour: hour,
        lateMinute: minute,
        updatedBy: current.updatedBy,
        baseProtocol: current.baseProtocol,
        ipPort: current.ipPort,
        apiPath: current.apiPath,
      );
    } catch (e) {
      throw Exception('Failed to update late hour: $e');
    }
  }

  /// Check if a given time is late
  Future<bool> isLateTime(DateTime dateTime) async {
    try {
      final settings = await getSettings();
      return settings.isLateTime(dateTime);
    } catch (e) {
      // Default to 9:00 AM if error
      return dateTime.hour > 9 || (dateTime.hour == 9 && dateTime.minute > 0);
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
        lateHour: current.lateHour,
        lateMinute: current.lateMinute,
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
        lateHour: current.lateHour,
        lateMinute: current.lateMinute,
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

  Future<void> setCurrentEmployee(
    String employeeCode,
    String employeeName,
  ) async {
    try {
      final current = await getSettings();
      await saveSettings(
        lateHour: current.lateHour,
        lateMinute: current.lateMinute,
        updatedBy: current.updatedBy,
        faceRecognitionEnabled: current.faceRecognitionEnabled,
        baseProtocol: current.baseProtocol,
        ipPort: current.ipPort,
        apiPath: current.apiPath,
        employeeCode: employeeCode,
        employeeName: employeeName,
      );
    } catch (e) {
      throw Exception('Failed to update current employee: $e');
    }
  }
}
