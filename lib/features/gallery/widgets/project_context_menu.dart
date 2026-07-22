import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import '../../../core/models/poster_project.dart';
import '../../../core/services/database_service.dart';
import '../../../core/services/file_manager_service.dart';
import '../../../widgets/hover_interaction.dart';

class ProjectContextMenu extends StatefulWidget {
  final PosterProject project;
  final Rect itemRect;
  final VoidCallback onAssignCategory;
  final VoidCallback onDelete;

  const ProjectContextMenu({
    super.key,
    required this.project,
    required this.itemRect,
    required this.onAssignCategory,
    required this.onDelete,
  });

  @override
  State<ProjectContextMenu> createState() => _ProjectContextMenuState();
}

class _ProjectContextMenuState extends State<ProjectContextMenu> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutExpo),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    const pillHeight = 60.0;
    const spacing = 20.0;
    
    final scaledHeight = widget.itemRect.height * 1.05;
    final heightDiff = (scaledHeight - widget.itemRect.height) / 2;
    
    final spaceBelow = screenSize.height - widget.itemRect.bottom - heightDiff;
    final showBelow = spaceBelow >= (pillHeight + spacing);
    
    double pillTop;
    if (showBelow) {
      pillTop = widget.itemRect.bottom + heightDiff + spacing;
    } else {
      pillTop = widget.itemRect.top - heightDiff - spacing - pillHeight;
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(color: Colors.transparent),
          ),
          Positioned(
            top: widget.itemRect.top,
            left: widget.itemRect.left,
            width: widget.itemRect.width,
            height: widget.itemRect.height,
            child: Hero(
              tag: widget.project.id ?? widget.project.hashCode,
              child: AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: child,
                  );
                },
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(128),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: widget.project.thumbnailBytes != null
                        ? Image.memory(
                            widget.project.thumbnailBytes!,
                            fit: BoxFit.cover,
                          )
                        : (kIsWeb 
                            ? (widget.project.webExportedImageBytes != null
                                ? Image.memory(
                                    widget.project.webExportedImageBytes!,
                                    fit: BoxFit.cover,
                                    cacheWidth: 300,
                                  )
                                : Image.network(
                                    widget.project.exportedImagePath ?? widget.project.originalImagePath,
                                    fit: BoxFit.cover,
                                    cacheWidth: 300,
                                  ))
                            : Image.file(
                                File(widget.project.exportedImagePath ?? widget.project.originalImagePath),
                                fit: BoxFit.cover,
                                cacheWidth: 300,
                              )),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: pillTop,
            left: widget.itemRect.center.dx,
            child: FractionalTranslation(
              translation: const Offset(-0.5, 0),
              child: FadeTransition(
                opacity: _controller,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                    CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
                  ),
                  child: Material(
                    color: const Color(0xFFF0F4F8),
                    borderRadius: BorderRadius.circular(30),
                    elevation: 8,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                        HoverInteraction(
                          child: IconButton(
                            icon: const Icon(Icons.arrow_downward_rounded, color: Colors.black87),
                            onPressed: () async {
                              Navigator.pop(context);
                              final path = widget.project.exportedImagePath ?? widget.project.originalImagePath;
                              
                              Uint8List? webBytes = widget.project.webExportedImageBytes;
                              if (kIsWeb && webBytes == null && widget.project.id != null) {
                                webBytes = await DatabaseService().getOriginalImageBytes(widget.project.id!);
                              }
                              
                              final ext = p.extension(path).isEmpty ? 'png' : p.extension(path).replaceAll('.', '');
                              final customName = FileManagerService.generateFileName(widget.project.exif, ext);
                              FileManagerService.shareOrSaveImage(
                                path,
                                !kIsWeb && Platform.isWindows,
                                saveToDevice: true,
                                webBytes: webBytes,
                                customFileName: customName,
                              );
                            },
                          ),
                        ),
                        HoverInteraction(
                          child: IconButton(
                            icon: const Icon(Icons.folder_outlined, color: Colors.black87),
                            tooltip: '분류',
                            onPressed: widget.onAssignCategory,
                          ),
                        ),
                        if (!kIsWeb && !Platform.isWindows)
                          HoverInteraction(
                            child: IconButton(
                              icon: const Icon(Icons.share_rounded, color: Colors.black87),
                              onPressed: () {
                                Navigator.pop(context);
                                final path = widget.project.exportedImagePath ?? widget.project.originalImagePath;
                                FileManagerService.shareOrSaveImage(path, false);
                              },
                            ),
                          ),
                        HoverInteraction(
                          child: IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                            onPressed: widget.onDelete,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          ),
        ],
      ),
    );
  }
}
