import 'package:flutter/material.dart';
import '../models/download_state.dart';
import '../theme/app_colors.dart';

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

class AnimatedFractionallySizedBox extends ImplicitlyAnimatedWidget {
  final double widthFactor;
  final AlignmentGeometry alignment;
  final Widget? child;

  const AnimatedFractionallySizedBox({
    super.key,
    required this.widthFactor,
    this.alignment = Alignment.centerLeft,
    this.child,
    required super.duration,
    super.curve = Curves.easeInOut,
  });

  @override
  ImplicitlyAnimatedWidgetState<AnimatedFractionallySizedBox> createState() =>
      _AnimatedFractionallySizedBoxState();
}

class _AnimatedFractionallySizedBoxState
    extends AnimatedWidgetBaseState<AnimatedFractionallySizedBox> {
  Tween<double>? _widthFactor;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _widthFactor = visitor(
      _widthFactor,
      widget.widthFactor,
      (dynamic value) => Tween<double>(begin: value as double),
    ) as Tween<double>?;
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: _widthFactor?.evaluate(animation) ?? widget.widthFactor,
      alignment: widget.alignment,
      child: widget.child,
    );
  }
}
