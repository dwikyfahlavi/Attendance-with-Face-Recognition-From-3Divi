// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'absen_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AbsenModelAdapter extends TypeAdapter<AbsenModel> {
  @override
  final int typeId = 2;

  @override
  AbsenModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AbsenModel(
      nik: fields[0] as String,
      nama: fields[1] as String,
      jamAbsen: fields[2] as DateTime,
      isLate: fields[3] as bool,
      status: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, AbsenModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.nik)
      ..writeByte(1)
      ..write(obj.nama)
      ..writeByte(2)
      ..write(obj.jamAbsen)
      ..writeByte(3)
      ..write(obj.isLate)
      ..writeByte(4)
      ..write(obj.status);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AbsenModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
