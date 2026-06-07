import 'dart:typed_data';
import 'package:hive/hive.dart';

import 'exif_data.dart';

part 'poster_project.g.dart';

@HiveType(typeId: 0)
class PosterProject extends HiveObject {
  @HiveField(0)
  int? id;

  @HiveField(1)
  String originalImagePath;
  @HiveField(2)
  String? exportedImagePath;

  @HiveField(3)
  ExifData exif;

  @HiveField(4)
  DateTime createdAt;
  @HiveField(5)
  bool exported = false;

  @HiveField(6)
  Uint8List? webExportedImageBytes;

  @HiveField(7)
  Uint8List? thumbnailBytes;

  PosterProject({
    this.id,
    required this.originalImagePath,
    this.exportedImagePath,
    required this.exif,
    required this.createdAt,
    this.exported = false,
    this.webExportedImageBytes,
    this.thumbnailBytes,
  });
}
