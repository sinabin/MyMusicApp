import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/premium_provider.dart';
import '../theme/app_color_scheme.dart';
import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';

/// 프리미엄 구매 바텀시트.
///
/// 5가지 프리미엄 기능 목록과 구매/복원 버튼을 표시.
/// [PremiumPurchaseSheet.show]로 호출.
class PremiumPurchaseSheet extends StatelessWidget {
  const PremiumPurchaseSheet({super.key});

  /// 구매 바텀시트를 모달로 표시.
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PremiumPurchaseSheet(),
    );
  }

  static const _features = [
    _FeatureItem(
      icon: Icons.auto_awesome,
      title: '스마트 추천 강화',
      description: '트렌딩, 비슷한 곡 등 섹션별 무제한 추천',
    ),
    _FeatureItem(
      icon: Icons.auto_fix_high,
      title: '자동 플레이리스트',
      description: '분위기·장르별 스마트 믹스 자동 생성',
    ),
    _FeatureItem(
      icon: Icons.lyrics,
      title: '가사 표시',
      description: '재생 중인 곡의 가사를 실시간 확인',
    ),
    _FeatureItem(
      icon: Icons.people,
      title: '아티스트 탐색',
      description: '즐겨듣는 아티스트의 인기곡 & 관련 아티스트',
    ),
    _FeatureItem(
      icon: Icons.directions_car,
      title: '차량 모드',
      description: '대형 버튼 UI + 음성 명령으로 안전 운전',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = AppColorScheme.of(context);
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXl)),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.xxl,
            AppSpacing.md,
            AppSpacing.xxl,
            AppSpacing.xxxl + MediaQuery.of(context).viewPadding.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: AppSizes.handleWidth,
                height: AppSizes.handleHeight,
                decoration: BoxDecoration(
                  color: cs.textTertiary,
                  borderRadius: BorderRadius.circular(AppSpacing.xxs),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Premium badge
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.primaryGradient,
                ),
                child: const Icon(
                  Icons.diamond,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Title
              Text(
                'Premium으로 업그레이드',
                style: AppTextStyles.titleLarge,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '한 번의 구매로 모든 기능을 영구 잠금 해제',
                style: AppTextStyles.body.copyWith(color: cs.textSecondary),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // Feature list
              ..._features.map((f) => _buildFeatureRow(cs, f)),

              const SizedBox(height: AppSpacing.xxl),

              // Purchase button
              Consumer<PremiumProvider>(
                builder: (context, premium, _) {
                  if (premium.isPremium) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: cs.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, color: cs.success),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            'Premium 활성화됨',
                            style: TextStyle(
                              color: cs.success,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final productReady = premium.product != null;
                  final canPurchase =
                      productReady && !premium.isPurchasing;

                  return Column(
                    children: [
                      // 구매 버튼
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: premium.isLoadingProduct
                            ? ElevatedButton(
                                onPressed: null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: cs.primary,
                                  disabledBackgroundColor:
                                      cs.primary.withValues(alpha: 0.4),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(AppTheme.radiusMd),
                                  ),
                                ),
                                child: const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),
                              )
                            : !productReady
                                ? OutlinedButton.icon(
                                    onPressed: () => premium.retryLoadProduct(),
                                    icon: Icon(Icons.refresh,
                                        color: cs.textSecondary, size: 18),
                                    label: Text(
                                      '스토어 연결 실패 — 탭하여 재시도',
                                      style: TextStyle(
                                        color: cs.textSecondary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(
                                          color: cs.textTertiary, width: 1),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                            AppTheme.radiusMd),
                                      ),
                                    ),
                                  )
                                : ElevatedButton(
                                    onPressed: canPurchase
                                        ? () => premium.purchase()
                                        : null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: cs.primary,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                            AppTheme.radiusMd),
                                      ),
                                    ),
                                    child: premium.isPurchasing
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Text(
                                            '${premium.product!.price}로 구매하기',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                  ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      // 복원 버튼
                      TextButton(
                        onPressed: premium.isRestoring ? null : () => premium.restore(),
                        child: premium.isRestoring
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: cs.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Text(
                                    '복원 중...',
                                    style: TextStyle(color: cs.textSecondary),
                                  ),
                                ],
                              )
                            : Text(
                                '이전 구매 복원',
                                style: TextStyle(color: cs.textSecondary),
                              ),
                      ),
                      // 에러 메시지
                      if (premium.error != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          premium.error!,
                          style: TextStyle(color: cs.error, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(AppColorScheme cs, _FeatureItem feature) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: cs.primarySurface,
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Icon(
              feature.icon,
              color: cs.primary,
              size: AppSizes.iconMd,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature.title,
                  style: AppTextStyles.tileTitle.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  feature.description,
                  style: AppTextStyles.caption.copyWith(color: cs.textTertiary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureItem {
  final IconData icon;
  final String title;
  final String description;
  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
  });
}
