import 'package:flutter/material.dart';

import '../theme/app_sizes.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';

/// Library 탭 상단의 빠른 접근 카드 위젯.
///
/// Favorites·Recent·All Songs 3가지 variant로 사용.
/// [LibraryScreen]의 Quick Access 섹션에서 표시.
class LibraryQuickCard extends StatelessWidget {
  /// 카드 아이콘.
  final IconData icon;

  /// 카드 레이블.
  final String label;

  /// 항목 수.
  final int count;

  /// 카드 강조 색상.
  final Color color;

  /// 탭 콜백.
  final VoidCallback onTap;

  const LibraryQuickCard({
    super.key,
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: Semantics(
          button: true,
          label: '$label $count곡',
          child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          onTap: onTap,
          child: Container(
            height: AppSizes.quickCardHeight,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: AppSpacing.sm,
                  right: AppSpacing.sm,
                  child: Icon(
                    icon,
                    size: AppSizes.iconXxl,
                    color: color.withValues(alpha: 0.2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '$count',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.screenTitle.copyWith(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        label,
                        style: AppTextStyles.caption.copyWith(
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }
}
