// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_category.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProjectCategoryAdapter extends TypeAdapter<ProjectCategory> {
  @override
  final int typeId = 3;

  @override
  ProjectCategory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProjectCategory(
      id: fields[0] as int,
      number: fields[1] as int,
      name: fields[2] as String,
      createdAt: fields[3] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, ProjectCategory obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.number)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectCategoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
