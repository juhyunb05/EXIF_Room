import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/gallery_provider.dart';
import '../../../core/models/project_category.dart';
import '../../../widgets/hover_interaction.dart';

class CategoryBar extends StatelessWidget {
  final Function() onAddCategory;
  final Function(ProjectCategory) onCategoryOptions;
  final Function() onInfoDialog;

  const CategoryBar({
    super.key,
    required this.onAddCategory,
    required this.onCategoryOptions,
    required this.onInfoDialog,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<GalleryProvider>(
      builder: (context, provider, child) {
        final categories = provider.categories;
        final selectedId = provider.selectedCategoryId;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            HoverInteraction(
              child: GestureDetector(
                onTap: () => provider.setCategoryFilter(null),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
                  child: Icon(
                    Icons.dashboard_rounded,
                    color: selectedId == null
                        ? const Color(0xFFF0F4F8)
                        : const Color(0xFF8E8E93),
                    size: 22,
                  ),
                ),
              ),
            ),
            for (final cat in categories)
              HoverInteraction(
                child: GestureDetector(
                  onTap: () => provider.setCategoryFilter(cat.id),
                  onLongPress: () => onCategoryOptions(cat),
                  onSecondaryTap: () => onCategoryOptions(cat),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          Icons.folder_rounded,
                          size: 24,
                          color: selectedId == cat.id
                              ? const Color(0xFFF0F4F8)
                              : const Color(0xFF8E8E93),
                        ),
                        Positioned(
                          top: 6,
                          child: Text(
                            '${cat.number}',
                            style: TextStyle(
                              fontFamily: 'Pretendard',
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: selectedId == cat.id
                                  ? const Color(0xFF222222)
                                  : const Color(0xFF1E1E1E),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            HoverInteraction(
              child: GestureDetector(
                onTap: onAddCategory,
                behavior: HitTestBehavior.opaque,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
                  child: Icon(Icons.add, color: Color(0xFFF0F4F8), size: 22),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
