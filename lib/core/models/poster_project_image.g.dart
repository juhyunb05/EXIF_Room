// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'poster_project_image.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PosterProjectImageAdapter extends TypeAdapter<PosterProjectImage> {
  @override
  final int typeId = 2;

  @override
  PosterProjectImage read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PosterProjectImage(
      id: fields[0] as int?,
      imageBytes: fields[1] as Uint8List,
    );
  }

  @override
  void write(BinaryWriter writer, PosterProjectImage obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.imageBytes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PosterProjectImageAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
