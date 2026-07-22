import 'dart:io';
import 'package:flutter/foundation.dart';
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

  @override
  void initState() {
    super.initState();
    _imageBytesFuture = _loadImageBytes();
  }

  Future<Uint8List?> _loadImageBytes() async {
    await Future.delayed(const Duration(milliseconds: 400));

    if (kIsWeb) {
      if (widget.project.id != null) {
        final bytes = await DatabaseService().getOriginalImageBytes(widget.project.id!);
        if (bytes != null) return bytes;
      }
      return widget.project.webExportedImageBytes;
    } else {
      final path = widget.project.exportedImagePath ?? widget.project.originalImagePath;
      final file = File(path);
      if (await file.exists()) {
        return await file.readAsBytes();
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.pop(context),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxHeight: 800),
            child: FutureBuilder<Uint8List?>(
              future: _imageBytesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 800,
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
                  return Image.memory(
                    bytes,
                    fit: BoxFit.contain,
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
      ),
    );
  }
}
