import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../core/models/exif_data.dart';
import '../core/models/edit_data.dart';
import '../core/utils/poster_layout_config.dart';
import 'loading_overlay.dart';

class PosterCanvas extends StatefulWidget {
  final String imagePath;
  final Uint8List? webImageBytes;
  final ExifData exifData;
  final EditData? editData;
  final int imageRotation;
  final bool isPreview;
  final Function(bool)? onImageLoaded;

  const PosterCanvas({
    super.key,
    required this.imagePath,
    this.webImageBytes,
    required this.exifData,
    this.editData,
    this.imageRotation = 0,
    this.isPreview = true,
    this.onImageLoaded,
  });

  @override
  State<PosterCanvas> createState() => _PosterCanvasState();
}

class _PosterCanvasState extends State<PosterCanvas> {
  bool _isLoaded = false;
  double? _imgAspectRatio;

  @override
  void initState() {
    super.initState();
    _resolveImageAspectRatio();
  }

  @override
  void didUpdateWidget(PosterCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imagePath != widget.imagePath ||
        oldWidget.webImageBytes != widget.webImageBytes) {
      _resolveImageAspectRatio();
    }
  }

  ImageProvider _getImageProvider() {
    if (widget.webImageBytes != null) {
      return MemoryImage(widget.webImageBytes!);
    } else if (kIsWeb) {
      return NetworkImage(widget.imagePath);
    } else {
      return FileImage(File(widget.imagePath));
    }
  }

  void _resolveImageAspectRatio() {
    final provider = _getImageProvider();
    provider.resolve(const ImageConfiguration()).addListener(
          ImageStreamListener((ImageInfo info, bool _) {
        if (mounted) {
          final w = info.image.width.toDouble();
          final h = info.image.height.toDouble();
          if (w > 0 && h > 0) {
            final aspect = w / h;
            if (_imgAspectRatio != aspect) {
              setState(() {
                _imgAspectRatio = aspect;
              });
            }
          }
        }
      }),
    );
  }

  String? _getBrandLogoPath(String? make) {
    if (make == null) return null;
    final cleanMake = make.trim().toLowerCase();
    if (cleanMake.contains('sony')) return 'assets/images/BrandLogos/sony-logo.svg';
    if (cleanMake.contains('canon')) return 'assets/images/BrandLogos/canon-logo.svg';
    if (cleanMake.contains('nikon')) return 'assets/images/BrandLogos/nikon-logo.svg';
    if (cleanMake.contains('apple')) return 'assets/images/BrandLogos/apple-logo.svg';
    if (cleanMake.contains('samsung')) return 'assets/images/BrandLogos/samsung-logo.svg';
    if (cleanMake.contains('ricoh')) return 'assets/images/BrandLogos/ricoh-logo.svg';
    if (cleanMake.contains('fujifilm') || cleanMake.contains('fuji')) {
      return 'assets/images/BrandLogos/fujifilm-logo.svg';
    }
    return null;
  }

  Widget _buildImageFrame(
    BuildContext context,
    Widget child,
    int? frame,
    bool wasSynchronouslyLoaded,
  ) {
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
        width: (widget.imageRotation % 2 != 0)
            ? PosterLayoutConfig.imageAreaWidthPortrait
            : PosterLayoutConfig.imageAreaWidthLandscape,
        height: (widget.imageRotation % 2 != 0)
            ? PosterLayoutConfig.imageAreaWidthLandscape
            : PosterLayoutConfig.imageAreaWidthPortrait,
      );
    }
    return child;
  }

  Widget _buildCroppedPhotoWidget(ImageProvider provider) {
    final edit = widget.editData;
    final imgAspect = _imgAspectRatio ?? (3.0 / 2.0);
    final targetWidth =
        (widget.imageRotation % 2 != 0)
            ? PosterLayoutConfig.imageAreaWidthPortrait
            : PosterLayoutConfig.imageAreaWidthLandscape;

    if (edit == null || edit.isIdentity) {
      final frameHeight = targetWidth / imgAspect;
      return SizedBox(
        width: targetWidth,
        height: frameHeight,
        child: Image(
          image: provider,
          width: targetWidth,
          height: frameHeight,
          fit: BoxFit.fill,
          filterQuality: FilterQuality.high,
          isAntiAlias: true,
          frameBuilder: _buildImageFrame,
        ),
      );
    }

    final cropRect = edit.cropRect;
    final fineAngle = edit.fineAngle;

    final cropL = cropRect.left;
    final cropT = cropRect.top;
    final cropW = cropRect.width;
    final cropH = cropRect.height;

    final cropAspect = imgAspect * (cropW / cropH);
    final frameWidth = targetWidth;
    final frameHeight = targetWidth / cropAspect;

    final fullW = frameWidth / cropW;
    final fullH = frameHeight / cropH;

    final cropCx = cropL + cropW / 2.0;
    final cropCy = cropT + cropH / 2.0;

    final shiftX = (0.5 - cropCx) * fullW;
    final shiftY = (0.5 - cropCy) * fullH;

    final rad = fineAngle * math.pi / 180.0;
    final cosA = math.cos(rad);
    final sinA = math.sin(rad);

    final corners = [
      Offset(cropL, cropT),
      Offset(cropL + cropW, cropT),
      Offset(cropL, cropT + cropH),
      Offset(cropL + cropW, cropT + cropH),
    ];

    double fillScale = 1.0;
    if (fineAngle != 0.0) {
      for (final c in corners) {
        final dx = c.dx - 0.5;
        final dy = c.dy - 0.5;
        final u = dx * cosA + dy * (1.0 / imgAspect) * sinA;
        final v = -dx * imgAspect * sinA + dy * cosA;
        final reqX = 2.0 * u.abs();
        final reqY = 2.0 * v.abs();
        if (reqX > fillScale) fillScale = reqX;
        if (reqY > fillScale) fillScale = reqY;
      }
    }

    return ClipRect(
      child: SizedBox(
        width: frameWidth,
        height: frameHeight,
        child: Stack(
          children: [
            Positioned(
              left: (frameWidth - fullW) / 2.0 + shiftX,
              top: (frameHeight - fullH) / 2.0 + shiftY,
              width: fullW,
              height: fullH,
              child: Transform.scale(
                scale: fillScale,
                alignment: Alignment.center,
                child: Transform.rotate(
                  angle: rad,
                  alignment: Alignment.center,
                  child: Image(
                    image: provider,
                    width: fullW,
                    height: fullH,
                    fit: BoxFit.fill,
                    filterQuality: FilterQuality.high,
                    isAntiAlias: true,
                    frameBuilder: _buildImageFrame,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = _getImageProvider();

    final canvas = Container(
      width: PosterLayoutConfig.exportWidth,
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: PosterLayoutConfig.topPadding),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: PosterLayoutConfig.horizontalPadding),
            child: RotatedBox(
              quarterTurns: widget.imageRotation,
              child: _buildCroppedPhotoWidget(provider),
            ),
          ),
          const SizedBox(height: PosterLayoutConfig.imageToInfoPadding),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: PosterLayoutConfig.horizontalPadding),
            child: _buildInfoLayout(),
          ),
          const SizedBox(height: PosterLayoutConfig.bottomPadding),
        ],
      ),
    );

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

    return canvas;
  }

  Widget _buildInfoLayout() {
    final logoPath = _getBrandLogoPath(widget.exifData.cameraMake);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 12,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.exifData.cameraMake != null &&
                  widget.exifData.cameraMake!.isNotEmpty) ...[
                logoPath != null
                    ? SvgPicture.asset(
                        logoPath,
                        height: PosterLayoutConfig.leftBrandHeight,
                        alignment: Alignment.centerLeft,
                        fit: BoxFit.contain,
                        colorFilter: const ColorFilter.mode(
                          Color(0xFF878787),
                          BlendMode.srcIn,
                        ),
                      )
                    : Text(
                        widget.exifData.cameraMake!.toUpperCase(),
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          color: const Color(0xFF6E6E6E),
                          fontSize: PosterLayoutConfig.fontSizeBrand,
                          fontWeight: FontWeight.w400,
                          height: 1.0,
                        ),
                      ),
                const SizedBox(height: PosterLayoutConfig.leftBrandSpacer),
              ],
              Text(
                widget.exifData.cameraName ?? "UNKNOWN CAMERA",
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  color: const Color(0xFF000000),
                  fontSize: PosterLayoutConfig.fontSizeModel,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: PosterLayoutConfig.modelToSpacer),
              if (widget.exifData.location != null &&
                  widget.exifData.location!.isNotEmpty)
                Text(
                  widget.exifData.location!.toUpperCase(),
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    color: const Color(0xFF000000),
                    fontSize: PosterLayoutConfig.fontSizeLocation,
                    fontWeight: FontWeight.w600,
                    height: 1.0,
                  ),
                ),
              if (widget.exifData.location != null &&
                  widget.exifData.location!.isNotEmpty)
                const SizedBox(height: PosterLayoutConfig.locationSpacer),
              Text(
                widget.exifData.shotDate != null
                    ? DateFormat("M/d/yyyy HH:mm")
                        .format(widget.exifData.shotDate!)
                    : "--/--/---- --:--",
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  color: const Color(0xFF525252),
                  fontSize: PosterLayoutConfig.fontSizeDate,
                  fontWeight: FontWeight.w400,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 10,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "ISO ${widget.exifData.iso ?? '--'}",
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        color: const Color(0xFF525252),
                        fontSize: PosterLayoutConfig.fontSizeSpec,
                        fontWeight: FontWeight.w400,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 80),
                    Text(
                      _formatShutterSpeed(widget.exifData.shutterSpeed),
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        color: const Color(0xFF525252),
                        fontSize: PosterLayoutConfig.fontSizeSpec,
                        fontWeight: FontWeight.w400,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
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
                            style: TextStyle(
                              fontFamily: 'Pretendard',
                              color: const Color(0xFF525252),
                              fontSize: PosterLayoutConfig.fontSizeSpec,
                              fontWeight: FontWeight.w400,
                              fontStyle: FontStyle.italic,
                              height: 1.0,
                            ),
                          ),
                          TextSpan(
                            text: "/${widget.exifData.aperture ?? '--'}",
                            style: TextStyle(
                              fontFamily: 'Pretendard',
                              color: const Color(0xFF525252),
                              fontSize: PosterLayoutConfig.fontSizeSpec,
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
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        color: const Color(0xFF525252),
                        fontSize: PosterLayoutConfig.fontSizeSpec,
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
