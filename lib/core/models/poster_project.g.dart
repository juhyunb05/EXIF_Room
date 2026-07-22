// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'poster_project.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PosterProjectAdapter extends TypeAdapter<PosterProject> {
  @override
  final int typeId = 0;

  @override
  PosterProject read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PosterProject(
      id: fields[0] as int?,
      originalImagePath: fields[1] as String,
      exportedImagePath: fields[2] as String?,
      exif: fields[3] as ExifData,
      createdAt: fields[4] as DateTime,
      exported: fields[5] as bool,
      webExportedImageBytes: fields[6] as Uint8List?,
      thumbnailBytes: fields[7] as Uint8List?,
      categoryId: fields[8] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, PosterProject obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.originalImagePath)
      ..writeByte(2)
      ..write(obj.exportedImagePath)
      ..writeByte(3)
      ..write(obj.exif)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.exported)
      ..writeByte(6)
      ..write(obj.webExportedImageBytes)
      ..writeByte(7)
      ..write(obj.thumbnailBytes)
      ..writeByte(8)
      ..write(obj.categoryId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PosterProjectAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
