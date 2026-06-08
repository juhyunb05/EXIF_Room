import 'dart:io';
import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/models/exif_data.dart';
import 'loading_overlay.dart';

class PosterCanvas extends StatefulWidget {
  final String imagePath;
  final Uint8List? webImageBytes;
  final ExifData exifData;
  final int imageRotation;
  final bool isPreview;
  final Function(bool)? onImageLoaded;

  const PosterCanvas({
    super.key,
    required this.imagePath,
    this.webImageBytes,
    required this.exifData,
    this.imageRotation = 0,
    this.isPreview = false,
    this.onImageLoaded,
  });

  @override
  State<PosterCanvas> createState() => _PosterCanvasState();
}

class _PosterCanvasState extends State<PosterCanvas> {
  bool _isLoaded = false;

  Widget _buildImageFrame(BuildContext context, Widget child, int? frame, bool wasSynchronouslyLoaded) {
    final isImageReady = wasSynchronouslyLoaded || frame != null;
    
    if (_isLoaded != isImageReady) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _isLoaded != isImageReady) {
          setState(() {
            _isLoaded = isImageReady;
          });
          if (widget.onImageLoaded != null) {
            widget.onImageLoaded!(_isLoaded);
          }
        }
      });
    }

    if (!isImageReady) {
      return SizedBox(
        width: (widget.imageRotation % 2 != 0) ? 1600 : 2400,
        height: (widget.imageRotation % 2 != 0) ? 2400 : 1600,
      );
    }
    return child;
  }

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
              quarterTurns: widget.imageRotation,
              child: widget.webImageBytes != null
                  ? Image.memory(
                      widget.webImageBytes!,
                      width: (widget.imageRotation % 2 != 0) ? null : 2400,
                      height: (widget.imageRotation % 2 != 0) ? 2400 : null,
                      fit: BoxFit.contain,
                      frameBuilder: _buildImageFrame,
                    )
                  : kIsWeb 
                      ? Image.network(
                          widget.imagePath,
                          width: (widget.imageRotation % 2 != 0) ? null : 2400,
                          height: (widget.imageRotation % 2 != 0) ? 2400 : null,
                          fit: BoxFit.contain,
                          frameBuilder: _buildImageFrame,
                        )
                      : Image.file(
                          File(widget.imagePath),
                          width: (widget.imageRotation % 2 != 0) ? null : 2400,
                          height: (widget.imageRotation % 2 != 0) ? 2400 : null,
                          fit: BoxFit.contain,
                          frameBuilder: _buildImageFrame,
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
    if (widget.isPreview) {
      return Stack(
        alignment: Alignment.center,
        children: [
          Opacity(
            opacity: _isLoaded ? 1.0 : 0.0,
            child: FittedBox(
              fit: BoxFit.contain,
              alignment: Alignment.center,
              child: canvas,
            ),
          ),
          if (!_isLoaded)
            const Positioned.fill(
              child: LoadingOverlay(
                isLoading: true,
                backgroundColor: Colors.transparent,
              ),
            ),
        ],
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
              if (widget.exifData.cameraMake != null && widget.exifData.cameraMake!.isNotEmpty)
                Text(
                  widget.exifData.cameraMake!.toUpperCase(),
                  style: TextStyle(fontFamily: 'Pretendard', 
                    color: const Color(0xFF6E6E6E),
                    fontSize: 56,
                    fontWeight: FontWeight.w400,
                    height: 1.0,
                  ),
                ),
              if (widget.exifData.cameraMake != null && widget.exifData.cameraMake!.isNotEmpty)
                const SizedBox(height: 24),
              Text(
                widget.exifData.cameraName ?? "UNKNOWN CAMERA",
                style: TextStyle(fontFamily: 'Pretendard', 
                  color: const Color(0xFF000000),
                  fontSize: 100,
                  fontWeight: FontWeight.w700, // Bold
                  letterSpacing: -1,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 56),
              if (widget.exifData.location != null && widget.exifData.location!.isNotEmpty)
                Text(
                  widget.exifData.location!.toUpperCase(),
                  style: TextStyle(fontFamily: 'Pretendard', 
                    color: const Color(0xFF000000),
                    fontSize: 72,
                    fontWeight: FontWeight.w600, // SemiBold
                    height: 1.0,
                  ),
                ),
              if (widget.exifData.location != null && widget.exifData.location!.isNotEmpty)
                const SizedBox(height: 16),
              Text(
                widget.exifData.shotDate != null
                    ? DateFormat("M/d/yyyy HH:mm").format(widget.exifData.shotDate!)
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
                      "ISO ${widget.exifData.iso ?? '--'}",
                      style: TextStyle(fontFamily: 'Pretendard', 
                        color: const Color(0xFF525252),
                        fontSize: 80,
                        fontWeight: FontWeight.w400,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 80),
                    Text(
                      _formatShutterSpeed(widget.exifData.shutterSpeed),
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
                            text: "/${widget.exifData.aperture ?? '--'}",
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
                      _formatFocalLength(widget.exifData.focalLength),
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
