import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// 다운로드 기록이 없을 때 표시하는 빈 상태 안내 위젯.
class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.music_off_rounded,
              size: 64,
              color: AppColors.textTertiary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'No downloads yet',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Your downloaded audio files will appear here',
              style: TextStyle(
                color: AppColors.textTertiary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
