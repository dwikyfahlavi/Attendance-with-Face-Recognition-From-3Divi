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
      lateHour: fields[0] as int,
      lateMinute: fields[1] as int,
      lastUpdated: fields[2] as DateTime,
      updatedBy: fields[3] as String?,
      faceRecognitionEnabled: fields[4] == null ? false : fields[4] as bool,
      baseProtocol: fields[5] as String,
      ipPort: fields[6] as String,
      apiPath: fields[7] as String,
    );
  }

  @override
  void write(BinaryWriter writer, SettingsModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.lateHour)
      ..writeByte(1)
      ..write(obj.lateMinute)
      ..writeByte(2)
      ..write(obj.lastUpdated)
      ..writeByte(3)
      ..write(obj.updatedBy)
      ..writeByte(4)
      ..write(obj.faceRecognitionEnabled)
      ..writeByte(5)
      ..write(obj.baseProtocol)
      ..writeByte(6)
      ..write(obj.ipPort)
      ..writeByte(7)
      ..write(obj.apiPath);
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
