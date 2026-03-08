import 'package:flutter/material.dart';
import '../models/download_state.dart';
import '../theme/app_colors.dart';

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            children: [
              Container(
                height: 8,
                width: double.infinity,
                color: AppColors.surfaceVariant,
              ),
              AnimatedFractionallySizedBox(
                duration: const Duration(milliseconds: 200),
                widthFactor: status.progress.clamp(0.0, 1.0),
                alignment: Alignment.centerLeft,
                child: Container(
                  height: 8,
                  decoration: const BoxDecoration(
                    gradient: AppColors.progressGradient,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Status text + cancel
        Row(
          children: [
            Expanded(
              child: Text(
                status.statusText ?? '',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),
            if (status.phase == DownloadPhase.downloading && onCancel != null)
              TextButton(
                onPressed: onCancel,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.error,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
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
