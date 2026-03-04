import 'package:hive/hive.dart';
import 'dart:convert';
import 'dart:typed_data';

part 'user_model.g.dart';

@HiveType(typeId: 0)
class RegisteredUser extends HiveObject {
  @HiveField(0)
  String employeeId;

  @HiveField(1)
  String employeeName;

  @HiveField(2)
  Uint8List? imageBytes;

  @HiveField(3)
  bool isAdmin;

  @HiveField(4)
  String? department;

  @HiveField(5)
  DateTime? lastAttendanceTime;

  @HiveField(8)
  String? employeeRole;

  @HiveField(9)
  String? companyCode;

  @HiveField(10)
  String? estateCode;

  @HiveField(11)
  String? plantCode;

  RegisteredUser({
    required this.employeeId,
    required this.employeeName,
    this.imageBytes,
    this.isAdmin = false,
    this.department,
    this.lastAttendanceTime,
    this.employeeRole,
    this.companyCode,
    this.estateCode,
    this.plantCode,
  });

  Map<String, dynamic> toApiJson() {
    return {
      'employeeId': employeeId,
      'employeeName': employeeName,
      'imageBytesBase64': imageBytes == null ? null : base64Encode(imageBytes!),
      'isAdmin': isAdmin,
      'department': department,
      'lastAttendanceTime': lastAttendanceTime?.toIso8601String(),
      'employeeRole': employeeRole,
      'companyCode': companyCode,
      'estateCode': estateCode,
      'plantCode': plantCode,
    };
  }

  factory RegisteredUser.fromApiJson(
    Map<String, dynamic> json,
    RegisteredUser? existing,
  ) {
    return RegisteredUser(
      employeeId: (json['employeeId'] ?? existing?.employeeId ?? ''),
      employeeName: (json['employeeName'] ?? existing?.employeeName ?? ''),
      imageBytes:
          _decodeBase64OrNull(json['employee_face_template']) ??
          existing?.imageBytes,
      isAdmin: json['isAdmin'] == true ? true : (existing?.isAdmin ?? false),
      department: json['department']?.toString() ?? existing?.department,
      lastAttendanceTime:
          _parseDateTimeOrNull(json['lastAttendanceTime']) ??
          existing?.lastAttendanceTime,

      employeeRole: json['employeeRole']?.toString() ?? existing?.employeeRole,
      companyCode: json['companyCode']?.toString() ?? existing?.companyCode,
      estateCode: json['estateCode']?.toString() ?? existing?.estateCode,
      plantCode: json['plantCode']?.toString() ?? existing?.plantCode,
    );
  }

  static Uint8List? _decodeBase64OrNull(String? value) {
    final raw = value;
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      // 1. Clean the string (remove the \x markers)
      String cleanHex = value!.replaceAll("\\x", "");

      // 2. Convert Hex to Bytes
      Uint8List bytes = Uint8List.fromList(
        List.generate(cleanHex.length ~/ 2, (i) {
          return int.parse(cleanHex.substring(i * 2, i * 2 + 2), radix: 16);
        }),
      );
      return bytes;
    } catch (e) {
      // print(e);
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
}
