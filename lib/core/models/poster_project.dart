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

  @HiveField(8)
  int? categoryId;

  @HiveField(9)
  List<int>? categoryIds;

  PosterProject({
    this.id,
    required this.originalImagePath,
    this.exportedImagePath,
    required this.exif,
    required this.createdAt,
    this.exported = false,
    this.webExportedImageBytes,
    this.thumbnailBytes,
    this.categoryId,
    this.categoryIds,
  });

  List<int> get categoryIdList {
    if (categoryIds != null && categoryIds!.isNotEmpty) {
      return categoryIds!;
    }
    if (categoryId != null) {
      return [categoryId!];
    }
    return [];
  }

  void setCategoryIds(List<int> ids) {
    categoryIds = ids;
    categoryId = ids.isNotEmpty ? ids.first : null;
  }
}
