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

  @HiveField(3, defaultValue: 'CheckIn')
  String type; // 'CheckIn' or 'CheckOut'

  @HiveField(4)
  String? serverId;

  @HiveField(5, defaultValue: false)
  bool isUploaded;

  @HiveField(6)
  DateTime? createdDate;

  @HiveField(7)
  DateTime? updatedDate;

  AbsenModel({
    required this.employeeId,
    required this.nama,
    required this.jamAbsen,
    this.type = 'CheckIn', // Default to CheckIn for backward compatibility
    this.serverId,
    this.isUploaded = false,
    this.createdDate,
    this.updatedDate,
  });

  @override
  String toString() {
    return 'AbsenModel(employeeId: $employeeId, nama: $nama, jamAbsen: $jamAbsen, type: $type, serverId: $serverId, isUploaded: $isUploaded, createdDate: $createdDate, updatedDate: $updatedDate)';
  }

  static List<AbsenModel> fromApi(Map<String, dynamic> json) {
    final employeeId = json['employee_id'] as String;
    final nama = json['employee_name'] as String;

    final createdDate = json['created_date'] != null
        ? DateTime.parse(json['created_date'] as String)
        : null;
    final updatedDate = json['updated_date'] != null
        ? DateTime.parse(json['updated_date'] as String)
        : null;
    final clockInStr = json['clock_in'] as String?;
    final clockOutStr = json['clock_out'] as String?;
    final list = <AbsenModel>[];
    if (clockInStr != null) {
      final clockIn = DateTime.parse(clockInStr);
      list.add(
        AbsenModel(
          employeeId: employeeId,
          nama: nama,
          jamAbsen: clockIn,
          type: 'CheckIn',
          serverId: json['id'],
          isUploaded: true,
          createdDate: createdDate,
          updatedDate: updatedDate,
        ),
      );
    }
    if (clockOutStr != null) {
      final clockOut = DateTime.parse(clockOutStr);
      list.add(
        AbsenModel(
          employeeId: employeeId,
          nama: nama,
          jamAbsen: clockOut,
          type: 'CheckOut',
          serverId: json['id'],
          isUploaded: true,
          createdDate: createdDate,
          updatedDate: updatedDate,
        ),
      );
    }
    return list;
  }
}
