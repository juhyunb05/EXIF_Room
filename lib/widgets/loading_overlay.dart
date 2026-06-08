import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final String text;
  final Color backgroundColor;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    this.text = '로딩중...',
    this.backgroundColor = const Color(0xCC000000), // Colors.black.withAlpha(204)
  });

  @override
  Widget build(BuildContext context) {
    if (!isLoading) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: backgroundColor,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.uiWhite,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: 120,
            height: 6,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: const LinearProgressIndicator(
                backgroundColor: Color(0xFF333333),
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.uiWhite),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
