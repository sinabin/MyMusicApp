import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/premium_provider.dart';
import '../theme/app_color_scheme.dart';
import '../theme/app_sizes.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import 'premium_purchase_sheet.dart';

/// 프리미엄 기능을 게이팅하는 래퍼 위젯.
///
/// [PremiumProvider.isPremium]이 false일 때 자식 위젯을 블러 처리하고
/// 잠금 아이콘 오버레이를 표시. 탭 시 [PremiumPurchaseSheet]를 호출.
class PremiumGate extends StatelessWidget {
  /// 게이팅할 자식 위젯.
  final Widget child;

  /// true 시 블러 + 잠금 오버레이 표시. false 시 자식 위젯 완전 숨김.
  final bool showTeaser;

  /// 기능 이름 (잠금 오버레이에 표시).
  final String? featureLabel;

  const PremiumGate({
    super.key,
    required this.child,
    this.showTeaser = true,
    this.featureLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<PremiumProvider>(
      builder: (context, premium, _) {
        if (premium.isPremium) return child;

        if (!showTeaser) {
          return const SizedBox.shrink();
        }

        final cs = AppColorScheme.of(context);

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => PremiumPurchaseSheet.show(context),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            child: Stack(
              children: [
                // 블러 처리된 자식 위젯
                ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                  child: IgnorePointer(child: child),
                ),
                // 잠금 오버레이
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: cs.scaffoldBackground.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.xs,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: AppSizes.iconHero,
                              height: AppSizes.iconHero,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: cs.primary.withValues(alpha: 0.15),
                              ),
                              child: Icon(
                                Icons.lock,
                                color: cs.primary,
                                size: AppSizes.iconLg,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              featureLabel ?? 'Premium',
                              style: TextStyle(
                                color: cs.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xxs),
                            Text(
                              '탭하여 잠금 해제',
                              style: TextStyle(
                                color: cs.textTertiary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
