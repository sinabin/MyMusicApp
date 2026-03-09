import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/download_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_durations.dart';
import '../theme/app_sizes.dart';
import '../theme/app_text_styles.dart';

/// [DownloadPhase]에 따라 외형이 변화하는 다운로드 버튼 위젯.
///
/// 대기·조회·다운로드·변환·완료·에러 각 단계별로 다른 UI를 표시.
/// [DownloadProvider]의 [DownloadStatus]를 받아 상태를 반영.
class DownloadButton extends StatefulWidget {
  final DownloadStatus status;
  final bool enabled;
  final VoidCallback? onPressed;
  final VoidCallback? onCancel;
  final VoidCallback? onRetry;

  const DownloadButton({
    super.key,
    required this.status,
    this.enabled = true,
    this.onPressed,
    this.onCancel,
    this.onRetry,
  });

  @override
  State<DownloadButton> createState() => _DownloadButtonState();
}

class _DownloadButtonState extends State<DownloadButton>
    with SingleTickerProviderStateMixin {
  static const _pillRadius = AppSizes.buttonHeight / 2;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: AppDurations.pulse,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(DownloadButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.status.phase == DownloadPhase.fetching) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppDurations.slow,
      curve: Curves.easeInOut,
      height: AppSizes.buttonHeight,
      width: double.infinity,
      child: _buildForPhase(),
    );
  }

  Widget _buildForPhase() {
    switch (widget.status.phase) {
      case DownloadPhase.idle:
        return _buildIdleButton();
      case DownloadPhase.fetching:
        return _buildFetchingButton();
      case DownloadPhase.downloading:
        return _buildProgressButton();
      case DownloadPhase.converting:
        return _buildConvertingButton();
      case DownloadPhase.completed:
        return _buildCompletedButton();
      case DownloadPhase.error:
        return _buildErrorButton();
    }
  }

  Widget _buildIdleButton() {
    return Material(
      borderRadius: BorderRadius.circular(_pillRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(_pillRadius),
        onTap: widget.enabled
            ? () {
                HapticFeedback.mediumImpact();
                widget.onPressed?.call();
              }
            : null,
        child: Ink(
          decoration: BoxDecoration(
            gradient: widget.enabled ? AppColors.primaryGradient : null,
            color: widget.enabled ? null : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(_pillRadius),
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.download_rounded,
                  color: widget.enabled ? Colors.white : AppColors.textTertiary,
                  size: AppSizes.iconLg,
                ),
                const SizedBox(width: 10),
                Text(
                  'Download Audio',
                  style: AppTextStyles.buttonText.copyWith(
                    color: widget.enabled ? Colors.white : AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFetchingButton() {
    return ScaleTransition(
      scale: _pulseAnimation,
      child: Container(
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(_pillRadius),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: AppSizes.indicatorSm,
                height: AppSizes.indicatorSm,
                child: const CircularProgressIndicator(
                  strokeWidth: AppSizes.strokeWidth,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Fetching...',
                style: AppTextStyles.buttonText.copyWith(
                  color: Colors.white,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressButton() {
    final progress = widget.status.progress;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(_pillRadius),
      ),
      child: Stack(
        children: [
          // Progress fill
          AnimatedFractionallySizedBox(
            duration: AppDurations.fast,
            widthFactor: progress.clamp(0.0, 1.0),
            alignment: Alignment.centerLeft,
            child: Container(
              decoration: BoxDecoration(
                gradient: AppColors.progressGradient,
                borderRadius: BorderRadius.circular(_pillRadius),
              ),
            ),
          ),
          // Content
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${(progress * 100).toInt()}%',
                  style: AppTextStyles.buttonText.copyWith(
                    color: Colors.white,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(width: 16),
                Semantics(
                  button: true,
                  label: '다운로드 취소',
                  child: GestureDetector(
                    onTap: widget.onCancel,
                    child: const Icon(Icons.close, color: Colors.white70, size: AppSizes.iconMd),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConvertingButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(_pillRadius),
      ),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: AppSizes.indicatorSm,
              height: AppSizes.indicatorSm,
              child: const CircularProgressIndicator(
                strokeWidth: AppSizes.strokeWidth,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Saving audio...',
              style: AppTextStyles.buttonText.copyWith(
                color: Colors.white,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletedButton() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.8, end: 1.0),
      duration: AppDurations.slow,
      curve: Curves.elasticOut,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.success,
          borderRadius: BorderRadius.circular(_pillRadius),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: AppSizes.iconLg),
              const SizedBox(width: 10),
              Text(
                'Download Complete!',
                style: AppTextStyles.buttonText.copyWith(
                  color: Colors.white,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorButton() {
    return Material(
      borderRadius: BorderRadius.circular(_pillRadius),
      color: AppColors.error,
      child: InkWell(
        borderRadius: BorderRadius.circular(_pillRadius),
        onTap: () {
          HapticFeedback.mediumImpact();
          widget.onRetry?.call();
        },
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.white, size: AppSizes.iconLg),
              const SizedBox(width: 10),
              Text(
                'Failed - Tap to Retry',
                style: AppTextStyles.buttonText.copyWith(
                  color: Colors.white,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
