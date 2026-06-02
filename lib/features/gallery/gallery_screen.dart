import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:heic_to_png_jpg/heic_to_png_jpg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

import '../../core/models/poster_project.dart';
import '../../core/services/database_service.dart';
import '../../core/services/exif_service.dart';
import '../../core/services/file_manager_service.dart';
import '../../theme/app_theme.dart';
import '../editor/editor_screen.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  List<PosterProject> _projects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    final projects = await DatabaseService().getAllProjects();
    setState(() {
      _projects = projects..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _isLoading = false;
    });
  }

  Future<void> _pickImage() async {
    String? selectedPath;

    if (kIsWeb) {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );
      selectedPath = image?.path;
    } else if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      final typeGroup = const XTypeGroup(
        label: 'Images',
        extensions: <String>['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'heic', 'heif'],
      );
      final file = await openFile(acceptedTypeGroups: <XTypeGroup>[typeGroup]);
      selectedPath = file?.path;
    } else {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );
      selectedPath = image?.path;
    }

    if (selectedPath != null) {
      String currentPath = selectedPath;
      final extension = p.extension(currentPath).toLowerCase();
      
      if (!kIsWeb && (extension == '.heic' || extension == '.heif')) {
        try {
          final outputPath = await HeicConverter.convertFile(
            inputPath: currentPath,
            format: ImageFormat.jpg,
            quality: 100,
          );
          if (outputPath != null) {
            currentPath = outputPath;
          }
        } catch (e) {
          debugPrint('Failed to convert HEIC: $e');
        }
      }

      final internalPath = kIsWeb ? currentPath : await FileManagerService.copyToInternalStorage(currentPath);
      final exif = await ExifService.extractExif(selectedPath);
      if (mounted) {
        final result = await Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                EditorScreen(imagePath: internalPath, initialExif: exif),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
          ),
        );
        if (result == true) _loadProjects();
      }
    }
  }

  void _viewImage(String path) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: InteractiveViewer(
            child: Image.file(
              File(path),
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }

  void _showProjectOptions(BuildContext context, PosterProject project, Rect itemRect) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black.withOpacity(0.8), // Dimming effect
        transitionDuration: const Duration(milliseconds: 350),
        reverseTransitionDuration: const Duration(milliseconds: 250),
        pageBuilder: (context, animation, secondaryAnimation) {
          return _ProjectContextMenu(
            project: project,
            itemRect: itemRect,
            onDelete: () async {
              Navigator.pop(context);
              if (project.id != null) {
                await DatabaseService().deleteProject(project.id!);
              }
              _loadProjects();
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Stack(
            children: [
              CustomScrollView(
                slivers: [
                  SliverAppBar(
                    backgroundColor: Colors.transparent,
                    surfaceTintColor: Colors.transparent,
                    floating: true,
                  ),
                  if (_isLoading)
                    const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_projects.isEmpty)
                    _buildEmptyState()
                  else
                    _buildProjectGrid(),
                ],
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 100,
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppTheme.backgroundColor.withOpacity(0.9),
                          AppTheme.backgroundColor.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 120,
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          AppTheme.backgroundColor.withOpacity(0.9),
                          AppTheme.backgroundColor.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
  floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: _pickImage,
        backgroundColor: Colors.transparent,
        elevation: 0,
        highlightElevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        child: const Icon(Icons.add, color: Colors.white, size: 36),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.canvasColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.black.withAlpha(50), blurRadius: 40),
                ],
              ),
              child: const Icon(
                Icons.camera_rounded,
                size: 48,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "No posters yet",
              style: TextStyle(fontFamily: 'Pretendard', 
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Transform your photos into art",
              style: TextStyle(color: AppTheme.subtitleColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectGrid() {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      sliver: SliverMasonryGrid.extent(
        maxCrossAxisExtent: 250,
        crossAxisSpacing: 16,
        mainAxisSpacing: 20,
        childCount: _projects.length,
        itemBuilder: (context, index) {
          final project = _projects[index];
          return Builder(
            builder: (itemContext) {
              return Hero(
                tag: project.id ?? project.hashCode,
                child: GestureDetector(
                  onTap: () => _viewImage(project.exportedImagePath ?? project.originalImagePath),
                  onLongPress: () {
                    final box = itemContext.findRenderObject() as RenderBox;
                    final rect = box.localToGlobal(Offset.zero) & box.size;
                    _showProjectOptions(context, project, rect);
                  },
                  onSecondaryTap: () {
                    final box = itemContext.findRenderObject() as RenderBox;
                    final rect = box.localToGlobal(Offset.zero) & box.size;
                    _showProjectOptions(context, project, rect);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(20),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Image.file(
                      File(
                        project.exportedImagePath ??
                            project.originalImagePath,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ProjectContextMenu extends StatefulWidget {
  final PosterProject project;
  final Rect itemRect;
  final VoidCallback onDelete;

  const _ProjectContextMenu({
    required this.project,
    required this.itemRect,
    required this.onDelete,
  });

  @override
  State<_ProjectContextMenu> createState() => _ProjectContextMenuState();
}

class _ProjectContextMenuState extends State<_ProjectContextMenu> with SingleTickerProviderStateMixin {
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
          // Dismiss background
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(color: Colors.transparent),
          ),
          Positioned(
            top: widget.itemRect.top,
            left: widget.itemRect.left,
            width: widget.itemRect.width,
            height: widget.itemRect.height,
            child: AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: child,
                );
              },
              child: Hero(
                tag: widget.project.id ?? widget.project.hashCode,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: kIsWeb 
                      ? Image.network(
                          widget.project.exportedImagePath ?? widget.project.originalImagePath,
                          fit: BoxFit.contain,
                        )
                      : Image.file(
                          File(widget.project.exportedImagePath ?? widget.project.originalImagePath),
                          fit: BoxFit.contain, // Maintain aspect ratio when scaled
                        ),
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
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    elevation: 8,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_downward_rounded, color: Colors.black87),
                          onPressed: () {
                            Navigator.pop(context);
                            final path = widget.project.exportedImagePath ?? widget.project.originalImagePath;
                            FileManagerService.shareOrSaveImage(path, Platform.isWindows, saveToDevice: true);
                          },
                        ),
                        if (!Platform.isWindows)
                          IconButton(
                            icon: const Icon(Icons.share_rounded, color: Colors.black87),
                            onPressed: () {
                              Navigator.pop(context);
                              final path = widget.project.exportedImagePath ?? widget.project.originalImagePath;
                              FileManagerService.shareOrSaveImage(path, false);
                            },
                          ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                          onPressed: widget.onDelete,
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
