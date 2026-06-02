// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exif_data.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ExifDataAdapter extends TypeAdapter<ExifData> {
  @override
  final int typeId = 1;

  @override
  ExifData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ExifData(
      cameraMake: fields[0] as String?,
      cameraName: fields[1] as String?,
      location: fields[2] as String?,
      shotDate: fields[3] as DateTime?,
      iso: fields[4] as String?,
      aperture: fields[5] as String?,
      shutterSpeed: fields[6] as String?,
      focalLength: fields[7] as String?,
      lensModel: fields[8] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ExifData obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.cameraMake)
      ..writeByte(1)
      ..write(obj.cameraName)
      ..writeByte(2)
      ..write(obj.location)
      ..writeByte(3)
      ..write(obj.shotDate)
      ..writeByte(4)
      ..write(obj.iso)
      ..writeByte(5)
      ..write(obj.aperture)
      ..writeByte(6)
      ..write(obj.shutterSpeed)
      ..writeByte(7)
      ..write(obj.focalLength)
      ..writeByte(8)
      ..write(obj.lensModel);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExifDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
