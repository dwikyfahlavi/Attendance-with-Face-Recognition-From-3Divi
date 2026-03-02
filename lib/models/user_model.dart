import 'package:hive/hive.dart';
import 'dart:convert';
import 'dart:typed_data';

part 'user_model.g.dart';

@HiveType(typeId: 0)
class RegisteredUser extends HiveObject {
  @HiveField(0)
  String nik;

  @HiveField(1)
  String nama;

  @HiveField(2)
  Uint8List? imageBytes;

  @HiveField(3)
  bool isAdmin;

  @HiveField(4)
  String? department;

  @HiveField(5)
  DateTime? lastAttendanceTime;

  @HiveField(6, defaultValue: false)
  bool hasTemplate;

  @HiveField(7)
  int? employeeId;

  @HiveField(8)
  String? employeeRole;

  @HiveField(9)
  String? companyCode;

  @HiveField(10)
  String? estateCode;

  @HiveField(11)
  String? plantCode;

  @HiveField(12)
  String? rawUserJson;

  @HiveField(13)
  Uint8List? templateBytes;

  RegisteredUser({
    required this.nik,
    required this.nama,
    this.imageBytes,
    this.isAdmin = false,
    this.department,
    this.lastAttendanceTime,
    this.hasTemplate = false,
    this.employeeId,
    this.employeeRole,
    this.companyCode,
    this.estateCode,
    this.plantCode,
    this.rawUserJson,
    this.templateBytes,
  });

  Map<String, dynamic> toApiJson() {
    return {
      'nik': nik,
      'nama': nama,
      'imageBytesBase64': imageBytes == null ? null : base64Encode(imageBytes!),
      'templateBytesBase64': templateBytes == null
          ? null
          : base64Encode(templateBytes!),
      'isAdmin': isAdmin,
      'department': department,
      'lastAttendanceTime': lastAttendanceTime?.toIso8601String(),
      'hasTemplate': hasTemplate,
      'employeeId': employeeId,
      'employeeRole': employeeRole,
      'companyCode': companyCode,
      'estateCode': estateCode,
      'plantCode': plantCode,
      'rawUserJson': rawUserJson,
    };
  }

  factory RegisteredUser.fromApiJson(Map<String, dynamic> json) {
    return RegisteredUser(
      nik: (json['nik'] ?? '').toString(),
      nama: (json['nama'] ?? '').toString(),
      imageBytes: _decodeBase64OrNull(json['imageBytesBase64']),
      templateBytes: _decodeBase64OrNull(json['templateBytesBase64']),
      isAdmin: json['isAdmin'] == true,
      department: json['department']?.toString(),
      lastAttendanceTime: _parseDateTimeOrNull(json['lastAttendanceTime']),
      hasTemplate: json['hasTemplate'] == true,
      employeeId: _parseIntOrNull(json['employeeId']),
      employeeRole: json['employeeRole']?.toString(),
      companyCode: json['companyCode']?.toString(),
      estateCode: json['estateCode']?.toString(),
      plantCode: json['plantCode']?.toString(),
      rawUserJson: json['rawUserJson']?.toString(),
    );
  }

  static Uint8List? _decodeBase64OrNull(dynamic value) {
    final raw = value?.toString();
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      return base64Decode(raw);
    } catch (_) {
      return null;
    }
  }

  static DateTime? _parseDateTimeOrNull(dynamic value) {
    final raw = value?.toString();
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return DateTime.tryParse(raw);
  }

  static int? _parseIntOrNull(dynamic value) {
    if (value is int) {
      return value;
    }

    final raw = value?.toString();
    if (raw == null || raw.isEmpty) {
      return null;
    }

    return int.tryParse(raw);
  }
}
