import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../../core/models/poster_project.dart';
import '../../../core/services/database_service.dart';
import '../../../widgets/loading_overlay.dart';

class ImageViewerDialog extends StatefulWidget {
  final PosterProject project;

  const ImageViewerDialog({super.key, required this.project});

  @override
  State<ImageViewerDialog> createState() => _ImageViewerDialogState();
}

class _ImageViewerDialogState extends State<ImageViewerDialog> {
  late final Future<Uint8List?> _imageBytesFuture;
  final TransformationController _transformationController = TransformationController();
  final GlobalKey _viewerKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _imageBytesFuture = _loadImageBytes();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  Future<Uint8List?> _loadImageBytes() async {
    await Future.delayed(const Duration(milliseconds: 200));

    if (kIsWeb) {
      if (widget.project.webExportedImageBytes != null) {
        return widget.project.webExportedImageBytes;
      }
      if (widget.project.id != null) {
        final bytes = await DatabaseService().getOriginalImageBytes(widget.project.id!);
        if (bytes != null) return bytes;
      }
      return widget.project.thumbnailBytes;
    } else {
      final path = widget.project.exportedImagePath ?? widget.project.originalImagePath;
      final file = File(path);
      if (await file.exists()) {
        return await file.readAsBytes();
      }
    }
    return null;
  }

  void _handlePointerScroll(PointerScrollEvent event) {
    final double zoomFactor = event.scrollDelta.dy < 0 ? 1.15 : 0.87;
    _zoomAtPosition(event.position, zoomFactor);
  }

  void _zoomAtPosition(Offset globalPosition, double zoomFactor) {
    final RenderBox? box = _viewerKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;

    final Offset localOffset = box.globalToLocal(globalPosition);
    final Matrix4 currentMatrix = _transformationController.value;
    final double currentScale = currentMatrix.getMaxScaleOnAxis();
    final double targetScale = (currentScale * zoomFactor).clamp(1.0, 5.0);
    final double actualFactor = targetScale / currentScale;

    if ((actualFactor - 1.0).abs() < 0.001) return;

    final Matrix4 translationMatrix = Matrix4.translationValues(localOffset.dx, localOffset.dy, 0.0)
      ..multiply(Matrix4.diagonal3Values(actualFactor, actualFactor, 1.0))
      ..multiply(Matrix4.translationValues(-localOffset.dx, -localOffset.dy, 0.0));

    final Matrix4 newMatrix = currentMatrix.clone()..multiply(translationMatrix);

    if (newMatrix.determinant() != 0) {
      _transformationController.value = newMatrix;
    }
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
  }

  void _handleDoubleTap(Offset doubleTapPosition) {
    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    if (currentScale > 1.2) {
      _resetZoom();
    } else {
      _zoomAtPosition(doubleTapPosition, 2.5);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background click listener to close
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.pop(context),
            child: const SizedBox.expand(),
          ),
          // Image Viewer Content
          Center(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 800),
              child: FutureBuilder<Uint8List?>(
                future: _imageBytesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 400,
                      width: double.infinity,
                      child: LoadingOverlay(
                        isLoading: true,
                        text: '로딩중...',
                        backgroundColor: Colors.transparent,
                      ),
                    );
                  }

                  final bytes = snapshot.data;
                  if (bytes != null) {
                    return Listener(
                      key: _viewerKey,
                      onPointerSignal: (pointerSignal) {
                        if (pointerSignal is PointerScrollEvent) {
                          _handlePointerScroll(pointerSignal);
                        }
                      },
                      child: GestureDetector(
                        onDoubleTapDown: (details) => _handleDoubleTap(details.globalPosition),
                        onDoubleTap: () {}, // Handled in onDoubleTapDown
                        child: InteractiveViewer(
                          transformationController: _transformationController,
                          trackpadScrollCausesScale: true,
                          minScale: 1.0,
                          maxScale: 5.0,
                          clipBehavior: Clip.none,
                          child: Image.memory(
                            bytes,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    );
                  } else {
                    return const Center(
                      child: Text(
                        '이미지를 불러올 수 없습니다.',
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
