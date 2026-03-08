import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/download_state.dart';
import '../theme/app_colors.dart';

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
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
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
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      height: 56,
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
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
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
            borderRadius: BorderRadius.circular(28),
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.download_rounded,
                  color: widget.enabled ? Colors.white : AppColors.textTertiary,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Text(
                  'Download Audio',
                  style: TextStyle(
                    color: widget.enabled ? Colors.white : AppColors.textTertiary,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
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
          borderRadius: BorderRadius.circular(28),
        ),
        child: const Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 10),
              Text(
                'Fetching...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
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
        borderRadius: BorderRadius.circular(28),
      ),
      child: Stack(
        children: [
          // Progress fill
          AnimatedFractionallySizedBox(
            duration: const Duration(milliseconds: 200),
            widthFactor: progress.clamp(0.0, 1.0),
            alignment: Alignment.centerLeft,
            child: Container(
              decoration: BoxDecoration(
                gradient: AppColors.progressGradient,
                borderRadius: BorderRadius.circular(28),
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
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: widget.onCancel,
                  child: const Icon(Icons.close, color: Colors.white70, size: 20),
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
        borderRadius: BorderRadius.circular(28),
      ),
      child: const Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 10),
            Text(
              'Saving audio...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
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
      duration: const Duration(milliseconds: 400),
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
          borderRadius: BorderRadius.circular(28),
        ),
        child: const Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 24),
              SizedBox(width: 10),
              Text(
                'Download Complete!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
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
      borderRadius: BorderRadius.circular(28),
      color: AppColors.error,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: () {
          HapticFeedback.mediumImpact();
          widget.onRetry?.call();
        },
        child: const Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white, size: 24),
              SizedBox(width: 10),
              Text(
                'Failed - Tap to Retry',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
