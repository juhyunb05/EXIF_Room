import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:exif/exif.dart' as exif_lib;
import 'package:intl/intl.dart';

import 'package:flutter/foundation.dart';

import '../models/exif_data.dart';

class ExifService {
  static Future<ExifData> extractExif(String imagePath) async {
    Map<String, exif_lib.IfdTag> tags;
    if (kIsWeb) {
      final response = await http.get(Uri.parse(imagePath));
      final fileBytes = response.bodyBytes;
      tags = await exif_lib.readExifFromBytes(fileBytes);
    } else {
      tags = await exif_lib.readExifFromFile(File(imagePath));
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
        // Silently fail
      }
    }

    final iso = tags['EXIF ISOSpeedRatings']?.toString();
    final aperture = tags['EXIF FNumber']?.toString();
    final shutterSpeed = tags['EXIF ExposureTime']?.toString();
    final focalLength = tags['EXIF FocalLengthIn35mmFilm']?.toString() ?? 
                        tags['EXIF FocalLength']?.toString();
    final lensModel =
        tags['EXIF LensModel']?.toString() ?? tags['EXIF LensSpec']?.toString();

    // Extract Location
    String? location;
    try {
      final latTag = tags['GPS GPSLatitude'];
      final lonTag = tags['GPS GPSLongitude'];
      final latRef = tags['GPS GPSLatitudeRef']?.printable;
      final lonRef = tags['GPS GPSLongitudeRef']?.printable;

      if (latTag != null && lonTag != null) {
        double? lat = _parseGpsTag(latTag);
        double? lon = _parseGpsTag(lonTag);
        
        if (lat != null && lon != null) {
          if (latRef == 'S') lat = -lat;
          if (lonRef == 'W') lon = -lon;
          location = await _getCityCountry(lat, lon);
        }
      }
    } catch (e) {
      // Ignore GPS errors
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

  static double? _parseGpsTag(dynamic tag) {
    try {
      final values = tag.values.toList();
      if (values.length >= 3) {
        double d = _toDouble(values[0]);
        double m = _toDouble(values[1]);
        double s = _toDouble(values[2]);
        return d + (m / 60.0) + (s / 3600.0);
      }
    } catch (e) {
      // Fail parsing
    }
    return null;
  }

  static double _toDouble(dynamic val) {
    if (val is num) return val.toDouble();
    if (val.runtimeType.toString() == 'Ratio') {
      return val.numerator / val.denominator;
    }
    // Fallback if dynamic Ratio parsing works
    try {
      return val.numerator / val.denominator;
    } catch (e) {
      return double.tryParse(val.toString()) ?? 0.0;
    }
  }

  static Future<String?> _getCityCountry(double lat, double lon) async {
    try {
      final url = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=$lat&lon=$lon&accept-language=ko');
      final response = await http.get(
        url,
        headers: kIsWeb
            ? {}
            : {
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
              },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['address'];
        if (address != null) {
          final city = address['city'] ?? address['town'] ?? address['village'] ?? address['county'] ?? address['suburb'];
          final country = address['country'];
          if (city != null && country != null) {
            return '$city, $country';
          } else if (country != null) {
            return country;
          }
        }
      }
    } catch (e) {
      // Ignore network errors
    }
    return null;
  }

  static String _formatAperture(String aperture) {
    if (aperture.contains('/')) {
      final parts = aperture.split('/');
      if (parts.length == 2) {
        final double val = double.parse(parts[0]) / double.parse(parts[1]);
        return val.toStringAsFixed(1);
      }
    }
    return aperture;
  }

  static String _formatShutter(String shutter) {
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
  }

  static String _formatFocalLength(String focal) {
    if (focal.contains('/')) {
      final parts = focal.split('/');
      if (parts.length == 2) {
        final double val = double.parse(parts[0]) / double.parse(parts[1]);
        return val.round().toString();
      }
    }
    return focal;
  }
}
