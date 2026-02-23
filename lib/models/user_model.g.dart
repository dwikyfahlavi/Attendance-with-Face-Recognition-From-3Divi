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
      imageBytes: fields[2] as Uint8List?,
      isAdmin: fields[3] as bool,
      department: fields[4] as String?,
      lastAttendanceTime: fields[5] as DateTime?,
      hasTemplate: fields[6] == null ? false : fields[6] as bool,
      employeeId: fields[7] as int?,
      employeeRole: fields[8] as String?,
      companyCode: fields[9] as String?,
      estateCode: fields[10] as String?,
      plantCode: fields[11] as String?,
      rawUserJson: fields[12] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, RegisteredUser obj) {
    writer
      ..writeByte(13)
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
      ..write(obj.lastAttendanceTime)
      ..writeByte(6)
      ..write(obj.hasTemplate)
      ..writeByte(7)
      ..write(obj.employeeId)
      ..writeByte(8)
      ..write(obj.employeeRole)
      ..writeByte(9)
      ..write(obj.companyCode)
      ..writeByte(10)
      ..write(obj.estateCode)
      ..writeByte(11)
      ..write(obj.plantCode)
      ..writeByte(12)
      ..write(obj.rawUserJson);
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
