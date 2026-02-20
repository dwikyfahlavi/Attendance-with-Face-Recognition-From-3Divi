import 'package:hive/hive.dart';

part 'admin_pin_model.g.dart';

@HiveType(typeId: 3)
class AdminPinModel extends HiveObject {
  @HiveField(0)
  String pinHash; // SHA256 hash of the PIN

  @HiveField(1)
  DateTime createdAt;

  @HiveField(2)
  String? createdBy;

  AdminPinModel({
    required this.pinHash,
    required this.createdAt,
    this.createdBy,
  });
}
