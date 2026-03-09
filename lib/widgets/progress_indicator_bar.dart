import 'package:flutter/material.dart';
import '../models/download_state.dart';
import '../theme/app_color_scheme.dart';
import '../theme/app_colors.dart';
import '../theme/app_durations.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';

/// 다운로드 진행률 바와 상태 텍스트·취소 버튼을 표시하는 위젯.
///
/// [DownloadStatus]의 진행률과 단계에 따라 UI를 갱신.
class ProgressIndicatorBar extends StatelessWidget {
  final DownloadStatus status;
  final VoidCallback? onCancel;

  const ProgressIndicatorBar({
    super.key,
    required this.status,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final cs = AppColorScheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          child: Stack(
            children: [
              Container(
                height: AppSpacing.sm,
                width: double.infinity,
                color: cs.surfaceVariant,
              ),
              AnimatedFractionallySizedBox(
                duration: AppDurations.fast,
                widthFactor: status.progress.clamp(0.0, 1.0),
                alignment: Alignment.centerLeft,
                child: Container(
                  height: AppSpacing.sm,
                  decoration: const BoxDecoration(
                    gradient: AppColors.progressGradient,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        // Status text + cancel
        Row(
          children: [
            Expanded(
              child: Text(
                status.statusText ?? '',
                style: TextStyle(
                  color: cs.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),
            if (status.phase == DownloadPhase.downloading && onCancel != null)
              TextButton(
                onPressed: onCancel,
                style: TextButton.styleFrom(
                  foregroundColor: cs.error,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Cancel', style: TextStyle(fontSize: 13)),
              ),
          ],
        ),
      ],
    );
  }
}
