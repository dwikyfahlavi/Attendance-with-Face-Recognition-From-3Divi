import 'package:hive/hive.dart';
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
  });
}
