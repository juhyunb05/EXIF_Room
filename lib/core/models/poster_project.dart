import 'package:isar/isar.dart';

import 'exif_data.dart';

part 'poster_project.g.dart';

@collection
class PosterProject {
  Id id = Isar.autoIncrement;

  late String originalImagePath;
  String? exportedImagePath;

  late ExifData exif;

  late DateTime createdAt;
  bool exported = false;

  PosterProject({
    required this.originalImagePath,
    this.exportedImagePath,
    required this.exif,
    required this.createdAt,
    this.exported = false,
  });
}
