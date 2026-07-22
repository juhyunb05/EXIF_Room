import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:exif/exif.dart' as exif_lib;
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';

import '../models/exif_data.dart';
import '../utils/logger.dart';

class _GpsValue {
  double value;
  _GpsValue(this.value);
}

class ExifService {
  static final Map<String, String?> _locationCache = {};

  static Future<ExifData> extractExif(String imagePath) async {
    Map<String, exif_lib.IfdTag> tags;
    try {
      if (kIsWeb) {
        final response = await http.get(Uri.parse(imagePath));
        if (response.statusCode < 200 || response.statusCode >= 300) {
          return ExifData();
        }
        final fileBytes = response.bodyBytes;
        tags = await exif_lib.readExifFromBytes(fileBytes);
      } else {
        tags = await exif_lib.readExifFromFile(File(imagePath));
      }
    } catch (e) {
      Logger.e('Failed to read EXIF from image', error: e);
      return ExifData();
    }

    if (tags.isEmpty) {
      return ExifData();
    }

    String? cameraName =
        tags['Image Model']?.toString() ?? tags['Hardware Model']?.toString();
    String? make = tags['Image Make']?.toString();

    if (make != null && cameraName != null) {
      final makeLower = make.toLowerCase();
      if (cameraName.toLowerCase().startsWith(makeLower)) {
        cameraName = cameraName.substring(make.length).trim();
      }
    }

    final dateTag =
        tags['Image DateTime']?.toString() ??
        tags['EXIF DateTimeOriginal']?.toString();
    DateTime? shotDate;
    if (dateTag != null) {
      try {
        shotDate = DateFormat("yyyy:MM:dd HH:mm:ss").parse(dateTag);
      } catch (e) {
        Logger.d('Failed to parse EXIF date: $e');
      }
    }

    final iso = tags['EXIF ISOSpeedRatings']?.toString();
    final aperture = tags['EXIF FNumber']?.toString();
    final shutterSpeed = tags['EXIF ExposureTime']?.toString();
    final focalLength = tags['EXIF FocalLengthIn35mmFilm']?.toString() ??
        tags['EXIF FocalLength']?.toString();
    final lensModel =
        tags['EXIF LensModel']?.toString() ?? tags['EXIF LensSpec']?.toString();

    String? location;
    try {
      final latTag = tags['GPS GPSLatitude'];
      final lonTag = tags['GPS GPSLongitude'];
      final latRef = tags['GPS GPSLatitudeRef']?.printable;
      final lonRef = tags['GPS GPSLongitudeRef']?.printable;

      if (latTag != null && lonTag != null) {
        final lat = _parseGpsTag(latTag);
        final lon = _parseGpsTag(lonTag);

        if (lat != null && lon != null) {
          if (latRef == 'S') lat.value = -lat.value;
          if (lonRef == 'W') lon.value = -lon.value;

          final cacheKey = '${lat.value},${lon.value}';
          location = _locationCache[cacheKey] ??
              await _getCityCountryWithTimeout(lat.value, lon.value);
          _locationCache[cacheKey] = location;
        }
      }
    } catch (e) {
      Logger.d('GPS location extraction failed', error: e);
    }

    return ExifData(
      cameraMake: make,
      cameraName: cameraName,
      location: location,
      shotDate: shotDate,
      iso: iso,
      aperture: aperture != null ? _formatAperture(aperture) : null,
      shutterSpeed: shutterSpeed != null ? _formatShutter(shutterSpeed) : null,
      focalLength: focalLength != null ? _formatFocalLength(focalLength) : null,
      lensModel: lensModel,
    );
  }

  static _GpsValue? _parseGpsTag(dynamic tag) {
    try {
      final values = tag.values.toList();
      if (values.length >= 3) {
        final d = _toDouble(values[0]);
        final m = _toDouble(values[1]);
        final s = _toDouble(values[2]);
        if (d != null && m != null && s != null) {
          return _GpsValue(d + (m / 60.0) + (s / 3600.0));
        }
      }
    } catch (e) {
      Logger.d('Failed to parse GPS tag', error: e);
    }
    return null;
  }

  static double? _toDouble(dynamic val) {
    try {
      if (val is num) return val.toDouble();

      if (val is! Map && val is! List) {
        final type = val.runtimeType.toString();
        if (type.contains('Ratio')) {
          try {
            final n = (val as dynamic).numerator as num;
            final dn = (val as dynamic).denominator as num;
            if (dn != 0) return (n / dn).toDouble();
          } catch (_) {
            // ignore
          }
        }
      }

      return double.tryParse(val.toString());
    } catch (e) {
      Logger.d('toDouble conversion failed', error: e);
      return null;
    }
  }

  static Future<String?> _getCityCountryWithTimeout(double lat, double lon) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=$lat&lon=$lon&accept-language=ko',
      );

      final response = await http
          .get(
        url,
        headers: kIsWeb
            ? {}
            : {
                'User-Agent':
                    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
              },
      ).timeout(
        const Duration(seconds: 4),
        onTimeout: () {
          Logger.d('Nominatim request timed out for $lat,$lon');
          return http.Response('', 504);
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['address'];
        if (address != null && address is Map) {
          final city = address['city'] ??
              address['town'] ??
              address['village'] ??
              address['county'] ??
              address['suburb'];
          final country = address['country'];
          if (city != null && country != null) {
            return '$city, $country';
          } else if (country != null) {
            return country;
          }
        }
      }
    } catch (e) {
      Logger.d('Nominatim request failed', error: e);
    }
    return null;
  }

  static String _formatAperture(String aperture) {
    try {
      if (aperture.contains('/')) {
        final parts = aperture.split('/');
        if (parts.length == 2) {
          final num = double.tryParse(parts[0]);
          final den = double.tryParse(parts[1]);
          if (num != null && den != null && den != 0) {
            final val = num / den;
            return val.toStringAsFixed(1);
          }
        }
      }
    } catch (e) {
      Logger.d('Aperture format failed', error: e);
    }
    return aperture;
  }

  static String _formatShutter(String shutter) {
    try {
      double? val;
      if (shutter.contains('/')) {
        final parts = shutter.split('/');
        if (parts.length == 2) {
          final num = double.tryParse(parts[0]);
          final den = double.tryParse(parts[1]);
          if (num != null && den != null && den != 0) {
            val = num / den;
          } else {
            return shutter;
          }
        } else {
          return shutter;
        }
      } else {
        val = double.tryParse(shutter);
      }

      if (val != null) {
        if (val >= 1.0) {
          if (val == val.roundToDouble()) {
            return val.round().toString();
          } else {
            return val.toStringAsFixed(1);
          }
        } else if (val > 0) {
          return "1/${(1 / val).round()}";
        }
      }
      return shutter;
    } catch (e) {
      Logger.d('Shutter format failed', error: e);
      return shutter;
    }
  }

  static String _formatFocalLength(String focal) {
    try {
      if (focal.contains('/')) {
        final parts = focal.split('/');
        if (parts.length == 2) {
          final num = double.tryParse(parts[0]);
          final den = double.tryParse(parts[1]);
          if (num != null && den != null && den != 0) {
            final val = num / den;
            return val.round().toString();
          }
        }
      }
    } catch (e) {
      Logger.d('FocalLength format failed', error: e);
    }
    return focal;
  }
}
