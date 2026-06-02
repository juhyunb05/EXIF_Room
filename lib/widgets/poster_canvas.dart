import 'dart:io';
import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/models/exif_data.dart';

class PosterCanvas extends StatelessWidget {
  final String imagePath;
  final Uint8List? webImageBytes;
  final ExifData exifData;
  final int imageRotation;
  final bool isPreview;

  const PosterCanvas({
    super.key,
    required this.imagePath,
    this.webImageBytes,
    required this.exifData,
    this.imageRotation = 0,
    this.isPreview = false,
  });

  @override
  Widget build(BuildContext context) {
    // 2800 Fixed width architecture
    final canvas = Container(
      width: 2800,
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 200),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 200),
            child: RotatedBox(
              quarterTurns: imageRotation,
              child: webImageBytes != null
                  ? Image.memory(
                      webImageBytes!,
                      width: (imageRotation % 2 != 0) ? null : 2400,
                      height: (imageRotation % 2 != 0) ? 2400 : null,
                      fit: BoxFit.contain,
                    )
                  : kIsWeb 
                      ? Image.network(
                          imagePath,
                          width: (imageRotation % 2 != 0) ? null : 2400,
                          height: (imageRotation % 2 != 0) ? 2400 : null,
                          fit: BoxFit.contain,
                        )
                      : Image.file(
                          File(imagePath),
                          width: (imageRotation % 2 != 0) ? null : 2400,
                          height: (imageRotation % 2 != 0) ? 2400 : null,
                          fit: BoxFit.contain,
                        ),
            ),
          ),
          const SizedBox(height: 320),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 200),
            child: _buildInfoLayout(),
          ),
          const SizedBox(height: 320),
        ],
      ),
    );

    // If it's for the UI preview, scale it down using FittedBox
    if (isPreview) {
      return FittedBox(
        fit: BoxFit.contain,
        alignment: Alignment.center,
        child: canvas,
      );
    }

    // For export, return the raw 2400px wide widget
    return canvas;
  }

  Widget _buildInfoLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // LEFT HALF: Camera, Location & Date
        Expanded(
          flex: 12,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (exifData.cameraMake != null && exifData.cameraMake!.isNotEmpty)
                Text(
                  exifData.cameraMake!.toUpperCase(),
                  style: TextStyle(fontFamily: 'Pretendard', 
                    color: const Color(0xFF6E6E6E),
                    fontSize: 56,
                    fontWeight: FontWeight.w400,
                    height: 1.0,
                  ),
                ),
              if (exifData.cameraMake != null && exifData.cameraMake!.isNotEmpty)
                const SizedBox(height: 24),
              Text(
                exifData.cameraName ?? "UNKNOWN CAMERA",
                style: TextStyle(fontFamily: 'Pretendard', 
                  color: const Color(0xFF000000),
                  fontSize: 100,
                  fontWeight: FontWeight.w700, // Bold
                  letterSpacing: -1,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 56),
              if (exifData.location != null && exifData.location!.isNotEmpty)
                Text(
                  exifData.location!.toUpperCase(),
                  style: TextStyle(fontFamily: 'Pretendard', 
                    color: const Color(0xFF000000),
                    fontSize: 72,
                    fontWeight: FontWeight.w600, // SemiBold
                    height: 1.0,
                  ),
                ),
              if (exifData.location != null && exifData.location!.isNotEmpty)
                const SizedBox(height: 16),
              Text(
                exifData.shotDate != null
                    ? DateFormat("M/d/yyyy HH:mm").format(exifData.shotDate!)
                    : "--/--/---- --:--",
                style: TextStyle(fontFamily: 'Pretendard', 
                  color: const Color(0xFF525252),
                  fontSize: 72,
                  fontWeight: FontWeight.w400,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),
        // RIGHT HALF: ISO, Shutter, F-Stop, Focal
        Expanded(
          flex: 10,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // COLUMN 1: ISO & Shutter Speed
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "ISO ${exifData.iso ?? '--'}",
                      style: TextStyle(fontFamily: 'Pretendard', 
                        color: const Color(0xFF525252),
                        fontSize: 80,
                        fontWeight: FontWeight.w400,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 80),
                    Text(
                      _formatShutterSpeed(exifData.shutterSpeed),
                      style: TextStyle(fontFamily: 'Pretendard', 
                        color: const Color(0xFF525252),
                        fontSize: 80,
                        fontWeight: FontWeight.w400,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
              // COLUMN 2: F-Stop & Focal Length
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: "f",
                            style: TextStyle(fontFamily: 'Pretendard', 
                              color: const Color(0xFF525252),
                              fontSize: 80,
                              fontWeight: FontWeight.w400,
                              fontStyle: FontStyle.italic,
                              height: 1.0,
                            ),
                          ),
                          TextSpan(
                            text: "/${exifData.aperture ?? '--'}",
                            style: TextStyle(fontFamily: 'Pretendard', 
                              color: const Color(0xFF525252),
                              fontSize: 80,
                              fontWeight: FontWeight.w400,
                              height: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 80),
                    Text(
                      _formatFocalLength(exifData.focalLength),
                      style: TextStyle(fontFamily: 'Pretendard', 
                        color: const Color(0xFF525252),
                        fontSize: 80,
                        fontWeight: FontWeight.w400,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatShutterSpeed(String? speed) {
    if (speed == null || speed.isEmpty) return "--s";
    if (speed.toLowerCase().endsWith('s')) return speed;
    return "${speed}s";
  }

  String _formatFocalLength(String? focal) {
    if (focal == null || focal.isEmpty) return "--mm";
    if (focal.toLowerCase().endsWith('mm')) return focal;
    return "${focal}mm";
  }
}
