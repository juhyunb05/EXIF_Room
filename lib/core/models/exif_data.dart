import 'package:hive/hive.dart';

part 'exif_data.g.dart';

@HiveType(typeId: 1)
class ExifData {
  @HiveField(0)
  String? cameraMake;
  @HiveField(1)
  String? cameraName;
  @HiveField(2)
  String? location;
  @HiveField(3)
  DateTime? shotDate;
  @HiveField(4)
  String? iso;
  @HiveField(5)
  String? aperture;
  @HiveField(6)
  String? shutterSpeed;
  @HiveField(7)
  String? focalLength;
  @HiveField(8)
  String? lensModel;

  ExifData({
    this.cameraMake,
    this.cameraName,
    this.location,
    this.shotDate,
    this.iso,
    this.aperture,
    this.shutterSpeed,
    this.focalLength,
    this.lensModel,
  });
}
