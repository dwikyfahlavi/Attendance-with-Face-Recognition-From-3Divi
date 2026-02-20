import 'package:hive/hive.dart';

part 'settings_model.g.dart';

@HiveType(typeId: 4)
class SettingsModel extends HiveObject {
  @HiveField(0)
  int lateHour; // Hour when attendance is considered late (24-hour format)

  @HiveField(1)
  int lateMinute; // Minute when attendance is considered late

  @HiveField(2)
  DateTime lastUpdated;

  @HiveField(3)
  String? updatedBy;

  @HiveField(4)
  bool faceRecognitionEnabled; // Enable/disable face recognition feature

  SettingsModel({
    this.lateHour = 9, // Default: 9:00 AM
    this.lateMinute = 0,
    required this.lastUpdated,
    this.updatedBy,
    this.faceRecognitionEnabled = true, // Default: enabled
  });

  /// Get late hour as TimeOfDay-like format (hour:minute)
  String get lateTimeString =>
      '${lateHour.toString().padLeft(2, '0')}:${lateMinute.toString().padLeft(2, '0')}';

  /// Check if a given time is late
  bool isLateTime(DateTime dateTime) {
    return dateTime.hour > lateHour ||
        (dateTime.hour == lateHour && dateTime.minute > lateMinute);
  }
}
