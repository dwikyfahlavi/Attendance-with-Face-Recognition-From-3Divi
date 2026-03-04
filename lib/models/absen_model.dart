import 'package:hive/hive.dart';

part 'absen_model.g.dart';

@HiveType(typeId: 2)
class AbsenModel extends HiveObject {
  @HiveField(0)
  String employeeId;

  @HiveField(1)
  String nama;

  @HiveField(2)
  DateTime jamAbsen;

  @HiveField(3)
  bool isLate;

  @HiveField(4)
  String status; // 'OnTime', 'Late', 'Absent'

  AbsenModel({
    required this.employeeId,
    required this.nama,
    required this.jamAbsen,
    this.isLate = false,
    this.status = 'OnTime',
  });

  @override
  toString() {
    return 'AbsenModel(employeeId: $employeeId, nama: $nama, jamAbsen: $jamAbsen, isLate: $isLate, status: $status)';
  }
}
