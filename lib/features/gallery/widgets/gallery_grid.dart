import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../../core/models/poster_project.dart';
import '../../../widgets/hover_interaction.dart';

class GalleryGrid extends StatelessWidget {
  final List<PosterProject> projects;
  final Function(PosterProject, Rect) onShowOptions;
  final Function(PosterProject) onViewImage;

  const GalleryGrid({
    super.key,
    required this.projects,
    required this.onShowOptions,
    required this.onViewImage,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      sliver: SliverMasonryGrid.extent(
        maxCrossAxisExtent: 250,
        crossAxisSpacing: 16,
        mainAxisSpacing: 20,
        childCount: projects.length,
        itemBuilder: (context, index) {
          final project = projects[index];
          return Builder(
            builder: (itemContext) {
              return Hero(
                tag: project.id ?? project.hashCode,
                child: HoverInteraction(
                  child: GestureDetector(
                    onTap: () => onViewImage(project),
                    onLongPress: () {
                      final box = itemContext.findRenderObject() as RenderBox;
                      final rect = box.localToGlobal(Offset.zero) & box.size;
                      onShowOptions(project, rect);
                    },
                    onSecondaryTap: () {
                      final box = itemContext.findRenderObject() as RenderBox;
                      final rect = box.localToGlobal(Offset.zero) & box.size;
                      onShowOptions(project, rect);
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
                      child: _buildProjectImage(project),
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

  Widget _buildProjectImage(PosterProject project) {
    if (project.thumbnailBytes != null) {
      return Image.memory(
        project.thumbnailBytes!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    }

    if (kIsWeb) {
      if (project.webExportedImageBytes != null) {
        return Image.memory(
          project.webExportedImageBytes!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
        );
      }

      final path = project.originalImagePath;
      if (path.startsWith('http://') || path.startsWith('https://')) {
        return Image.network(
          path,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
        );
      }

      return _buildPlaceholder();
    }

    final path = project.exportedImagePath ?? project.originalImagePath;
    final file = File(path);
    if (file.existsSync()) {
      return Image.file(
        file,
        fit: BoxFit.cover,
        cacheWidth: 300,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      height: 200,
      color: Colors.grey.shade900,
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.broken_image_rounded, color: Colors.grey, size: 36),
            SizedBox(height: 8),
            Text(
              '이미지를 불러올 수 없음',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
