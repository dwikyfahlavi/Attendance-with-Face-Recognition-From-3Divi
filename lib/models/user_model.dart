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
  Uint8List imageBytes;

  @HiveField(3)
  bool isAdmin;

  @HiveField(4)
  String? department;

  @HiveField(5)
  DateTime? lastAttendanceTime;

  RegisteredUser({
    required this.nik,
    required this.nama,
    required this.imageBytes,
    this.isAdmin = false,
    this.department,
    this.lastAttendanceTime,
  });
}
