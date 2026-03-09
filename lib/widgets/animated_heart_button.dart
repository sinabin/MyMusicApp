import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_durations.dart';
import '../theme/app_sizes.dart';

/// 즐겨찾기 토글용 애니메이션 하트 버튼.
///
/// 탭 시 스케일 애니메이션(0.8→1.2→1.0)과 색상 전환을 수행.
/// [FullPlayerScreen], [TrackListTile], [FavoritesScreen] 등에서 공유.
class AnimatedHeartButton extends StatefulWidget {
  /// 즐겨찾기 상태.
  final bool isFavorite;

  /// 토글 콜백.
  final VoidCallback onToggle;

  /// 아이콘 크기.
  final double size;

  const AnimatedHeartButton({
    super.key,
    required this.isFavorite,
    required this.onToggle,
    this.size = AppSizes.iconMd,
  });

  @override
  State<AnimatedHeartButton> createState() => _AnimatedHeartButtonState();
}

class _AnimatedHeartButtonState extends State<AnimatedHeartButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppDurations.fast,
      vsync: this,
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.8), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.8, end: 1.2), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 30),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    _controller.forward(from: 0);
    widget.onToggle();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.isFavorite ? '좋아요 해제' : '좋아요',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _handleTap,
        child: SizedBox(
        width: AppSizes.touchTarget,
        height: AppSizes.touchTarget,
        child: Center(
          child: AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Icon(
                  widget.isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: widget.isFavorite
                      ? AppColors.error
                      : AppColors.textSecondary,
                  size: widget.size,
                ),
              );
            },
          ),
        ),
      ),
      ),
    );
  }
}
