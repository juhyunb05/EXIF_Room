import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/hover_interaction.dart';

class EditorActionPanel extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onRotate;

  const EditorActionPanel({
    super.key,
    required this.onEdit,
    required this.onRotate,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: HoverInteraction(
            child: InkWell(
              onTap: onEdit,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    vertical: 14, horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C2E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppTheme.uiWhite.withAlpha(30)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.tune_rounded,
                        color: AppTheme.uiWhite, size: 18),
                    SizedBox(width: 8),
                    Text(
                      '편집하기',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.uiWhite,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: HoverInteraction(
            child: InkWell(
              onTap: onRotate,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    vertical: 14, horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C2E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppTheme.uiWhite.withAlpha(30)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.rotate_right_rounded,
                        color: AppTheme.uiWhite, size: 18),
                    SizedBox(width: 6),
                    Text(
                      '90° 회전',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.uiWhite,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
