// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RegisteredUserAdapter extends TypeAdapter<RegisteredUser> {
  @override
  final int typeId = 0;

  @override
  RegisteredUser read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RegisteredUser(
      nik: fields[0] as String,
      nama: fields[1] as String,
      imageBytes: fields[2] as Uint8List,
      isAdmin: fields[3] as bool,
      department: fields[4] as String?,
      lastAttendanceTime: fields[5] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, RegisteredUser obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.nik)
      ..writeByte(1)
      ..write(obj.nama)
      ..writeByte(2)
      ..write(obj.imageBytes)
      ..writeByte(3)
      ..write(obj.isAdmin)
      ..writeByte(4)
      ..write(obj.department)
      ..writeByte(5)
      ..write(obj.lastAttendanceTime);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RegisteredUserAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
