import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/recommendation.dart';
import '../theme/app_color_scheme.dart';
import '../theme/app_sizes.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import '../utils/format_utils.dart';

/// 추천 곡 카드 위젯.
///
/// 썸네일·제목·채널명·재생 시간·추천 사유를 표시하며,
/// 다운로드 버튼과 Dismissible 스와이프를 제공.
class RecommendationCard extends StatelessWidget {
  /// 추천 데이터.
  final Recommendation recommendation;

  /// 다운로드 버튼 콜백.
  final VoidCallback? onDownload;

  /// dismiss 콜백.
  final VoidCallback? onDismiss;

  /// 카드 탭 콜백 (상세 정보 표시용).
  final VoidCallback? onTap;

  /// 다운로드 진행 중 여부.
  final bool isDownloading;

  const RecommendationCard({
    super.key,
    required this.recommendation,
    this.onDownload,
    this.onDismiss,
    this.onTap,
    this.isDownloading = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = AppColorScheme.of(context);
    return Dismissible(
      key: ValueKey(recommendation.videoId),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.xl),
        decoration: BoxDecoration(
          color: cs.error.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.not_interested, color: cs.error),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '관심 없음',
              style: TextStyle(color: cs.error, fontSize: 11),
            ),
          ],
        ),
      ),
      onDismissed: (_) => onDismiss?.call(),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: cs.border, width: 1),
        ),
        child: Row(
          children: [
            // 탭 영역: 썸네일 + 정보
            Expanded(
              child: Semantics(
                button: true,
                label: '${recommendation.title}, ${recommendation.channelName}',
                child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onTap,
                child: Row(
                  children: [
                    // 썸네일
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      child: SizedBox(
                        width: AppSizes.thumbnailXl,
                        height: AppSizes.searchThumbHeight,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CachedNetworkImage(
                              imageUrl: recommendation.thumbnailUrl,
                              fit: BoxFit.cover,
                              placeholder: (_, _) => Container(
                                color: cs.surfaceVariant,
                                child: Icon(
                                  Icons.music_note,
                                  color: cs.textTertiary,
                                  size: AppSizes.iconLg,
                                ),
                              ),
                              errorWidget: (_, _, _) => Container(
                                color: cs.surfaceVariant,
                                child: Icon(
                                  Icons.music_note,
                                  color: cs.textTertiary,
                                  size: AppSizes.iconLg,
                                ),
                              ),
                            ),
                            // 재생 시간 오버레이
                            if (recommendation.duration != null)
                              Positioned(
                                right: AppSpacing.xs,
                                bottom: AppSpacing.xs,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.xs,
                                    vertical: AppSpacing.xxs,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.7),
                                    borderRadius: BorderRadius.circular(AppSpacing.xs),
                                  ),
                                  child: Text(
                                    FormatUtils.duration(recommendation.duration!),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    // 정보
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            recommendation.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodySmall,
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            recommendation.channelName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: cs.textTertiary,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: AppSpacing.xxs,
                            ),
                            decoration: BoxDecoration(
                              color: cs.primarySurface,
                              borderRadius: BorderRadius.circular(AppSpacing.xs),
                            ),
                            child: Text(
                              recommendation.reason,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: cs.primaryLight,
                                fontSize: 10,
                              ),
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
            const SizedBox(width: AppSpacing.sm),
            // 다운로드 버튼
            IconButton(
              tooltip: isDownloading ? '다운로드 중' : '다운로드',
              icon: isDownloading
                  ? SizedBox(
                      width: AppSizes.indicatorSm,
                      height: AppSizes.indicatorSm,
                      child: CircularProgressIndicator(
                        strokeWidth: AppSizes.strokeWidth,
                        color: cs.primary,
                      ),
                    )
                  : Icon(
                      Icons.download_rounded,
                      color: cs.primary,
                      size: AppSizes.iconLg,
                    ),
              onPressed: isDownloading ? null : onDownload,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: AppSizes.touchTarget,
                minHeight: AppSizes.touchTarget,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
