import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_colors.dart';
import '../theme/app_durations.dart';
import '../theme/app_sizes.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// 콘텐츠가 없는 화면에 표시하는 범용 빈 상태 위젯.
///
/// 아이콘·제목·설명을 스태거 애니메이션으로 표시하며,
/// 선택적 CTA 버튼으로 다음 행동을 유도.
/// [icon]과 [title]만 지정하면 최소 형태로 사용 가능.
class EmptyStateWidget extends StatelessWidget {
  /// 표시할 아이콘.
  final IconData icon;

  /// 제목 메시지.
  final String title;

  /// 부가 설명 메시지.
  final String? description;

  /// CTA 버튼 라벨.
  final String? actionLabel;

  /// CTA 버튼 아이콘.
  final IconData? actionIcon;

  /// CTA 버튼 콜백.
  final VoidCallback? onAction;

  const EmptyStateWidget({
    super.key,
    this.icon = Icons.music_off_rounded,
    this.title = 'No downloads yet',
    this.description = 'Your downloaded audio files will appear here',
    this.actionLabel,
    this.actionIcon,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.xxxxl,
          horizontal: AppSpacing.xxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 아이콘: 부드러운 펄스 애니메이션.
            Icon(
              icon,
              size: AppSizes.iconJumbo,
              color: AppColors.textTertiary.withValues(alpha: 0.5),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scaleXY(
                  end: 1.06,
                  duration: AppDurations.pulse * 2,
                  curve: Curves.easeInOut,
                ),
            const SizedBox(height: AppSpacing.lg),

            // 제목: 페이드인 + 슬라이드.
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.inputText.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            )
                .animate()
                .fadeIn(duration: AppDurations.normal)
                .slideY(begin: 0.2, end: 0),

            // 설명: 지연 페이드인.
            if (description != null) ...[
              const SizedBox(height: 6),
              Text(
                description!,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textTertiary,
                  fontWeight: FontWeight.w400,
                ),
              ).animate().fadeIn(
                    duration: AppDurations.normal,
                    delay: 100.ms,
                  ),
            ],

            // CTA 버튼: 지연 페이드인.
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.xl),
              TextButton.icon(
                onPressed: onAction,
                icon: actionIcon != null
                    ? Icon(actionIcon, size: AppSizes.iconMsl)
                    : const SizedBox.shrink(),
                label: Text(actionLabel!),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                ),
              ).animate().fadeIn(
                    duration: AppDurations.normal,
                    delay: 200.ms,
                  ),
            ],
          ],
        ),
      ),
    );
  }
}
