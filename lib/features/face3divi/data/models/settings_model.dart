import 'package:hive/hive.dart';

part 'settings_model.g.dart';

@HiveType(typeId: 4)
class SettingsModel extends HiveObject {
  @HiveField(0)
  int checkInHour; // Hour for check-in (24-hour format)

  @HiveField(1)
  int checkInMinute; // Minute for check-in

  @HiveField(2)
  int checkOutHour; // Hour for check-out (24-hour format)

  @HiveField(3)
  int checkOutMinute; // Minute for check-out

  @HiveField(4)
  DateTime lastUpdated;

  @HiveField(5)
  String? updatedBy;

  @HiveField(6, defaultValue: false)
  bool faceRecognitionEnabled; // Enable/disable face recognition feature

  @HiveField(7)
  String baseProtocol;

  @HiveField(8)
  String ipPort;

  @HiveField(9)
  String apiPath;

  @HiveField(10)
  String? employeeCode; // Employee code for face template uploads

  @HiveField(11)
  String? employeeName; // Employee name for display purposes

  @HiveField(12)
  String? userId;

  @HiveField(13)
  String? unattendanceCode;

  @HiveField(14)
  String? attendanceCode;

  SettingsModel({
    this.checkInHour = 9, // Default: 9:00 AM
    this.checkInMinute = 0,
    this.checkOutHour = 18, // Default: 6:00 PM
    this.checkOutMinute = 0,
    required this.lastUpdated,
    this.updatedBy,
    this.faceRecognitionEnabled = true, // Default: enabled
    this.baseProtocol = 'http://',
    this.ipPort = '172.21.23.70:81',
    this.apiPath = '/api/v1_1',
    this.employeeCode = '',
    this.employeeName = '',
    this.userId,
    this.unattendanceCode = '',
    this.attendanceCode = '',
  });

  String get apiBaseUrl => '$baseProtocol$ipPort$apiPath';

  /// Get check-in time as string
  String get checkInTimeString =>
      '${checkInHour.toString().padLeft(2, '0')}:${checkInMinute.toString().padLeft(2, '0')}';

  /// Get check-out time as string
  String get checkOutTimeString =>
      '${checkOutHour.toString().padLeft(2, '0')}:${checkOutMinute.toString().padLeft(2, '0')}';

  /// Check if a given time is late (only for CheckIn)
  bool isLateTime(DateTime dateTime, String type) {
    if (type == 'CheckOut') return false; // No late for check-outs
    final checkInTime = DateTime(
      dateTime.year,
      dateTime.month,
      dateTime.day,
      checkInHour,
      checkInMinute,
    );
    return dateTime.isAfter(checkInTime);
  }
}
