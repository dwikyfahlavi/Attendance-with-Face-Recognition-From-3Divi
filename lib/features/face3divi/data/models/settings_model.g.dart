// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SettingsModelAdapter extends TypeAdapter<SettingsModel> {
  @override
  final int typeId = 4;

  @override
  SettingsModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SettingsModel(
      checkInHour: fields[0] as int,
      checkInMinute: fields[1] as int,
      checkOutHour: fields[2] as int,
      checkOutMinute: fields[3] as int,
      lastUpdated: fields[4] as DateTime,
      updatedBy: fields[5] as String?,
      faceRecognitionEnabled: fields[6] == null ? false : fields[6] as bool,
      baseProtocol: fields[7] as String,
      ipPort: fields[8] as String,
      apiPath: fields[9] as String,
      employeeCode: fields[10] as String?,
      employeeName: fields[11] as String?,
      userId: fields[12] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, SettingsModel obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.checkInHour)
      ..writeByte(1)
      ..write(obj.checkInMinute)
      ..writeByte(2)
      ..write(obj.checkOutHour)
      ..writeByte(3)
      ..write(obj.checkOutMinute)
      ..writeByte(4)
      ..write(obj.lastUpdated)
      ..writeByte(5)
      ..write(obj.updatedBy)
      ..writeByte(6)
      ..write(obj.faceRecognitionEnabled)
      ..writeByte(7)
      ..write(obj.baseProtocol)
      ..writeByte(8)
      ..write(obj.ipPort)
      ..writeByte(9)
      ..write(obj.apiPath)
      ..writeByte(10)
      ..write(obj.employeeCode)
      ..writeByte(11)
      ..write(obj.employeeName)
      ..writeByte(12)
      ..write(obj.userId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SettingsModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
