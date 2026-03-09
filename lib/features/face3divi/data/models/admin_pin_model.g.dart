// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_pin_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AdminPinModelAdapter extends TypeAdapter<AdminPinModel> {
  @override
  final int typeId = 3;

  @override
  AdminPinModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AdminPinModel(
      pinHash: fields[0] as String,
      createdAt: fields[1] as DateTime,
      createdBy: fields[2] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, AdminPinModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.pinHash)
      ..writeByte(1)
      ..write(obj.createdAt)
      ..writeByte(2)
      ..write(obj.createdBy);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminPinModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
