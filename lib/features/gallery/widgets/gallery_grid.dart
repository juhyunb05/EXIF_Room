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
                      child: project.thumbnailBytes != null
                          ? Image.memory(
                              project.thumbnailBytes!,
                              fit: BoxFit.cover,
                            )
                          : (kIsWeb
                              ? (project.webExportedImageBytes != null
                                  ? Image.memory(
                                      project.webExportedImageBytes!,
                                      cacheWidth: 300,
                                    )
                                  : Image.network(
                                      project.originalImagePath,
                                      cacheWidth: 300,
                                    ))
                              : Image.file(
                                  File(
                                    project.exportedImagePath ??
                                        project.originalImagePath,
                                  ),
                                  cacheWidth: 300,
                                )),
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
