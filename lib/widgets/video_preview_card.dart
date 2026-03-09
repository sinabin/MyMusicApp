import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../models/video_info.dart';
import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';

/// 조회된 YouTube 영상의 썸네일·제목·채널·재생 시간을 미리보기로 표시하는 카드 위젯.
///
/// [VideoInfo] 데이터를 받아 렌더링하며, [HomeScreen]에서 URL 입력 후 표시.
class VideoPreviewCard extends StatelessWidget {
  final VideoInfo videoInfo;

  const VideoPreviewCard({super.key, required this.videoInfo});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              child: CachedNetworkImage(
                imageUrl: videoInfo.thumbnailUrl,
                width: AppSizes.videoPreviewWidth,
                height: AppSizes.videoPreviewHeight,
                fit: BoxFit.cover,
                placeholder: (context, url) => Shimmer.fromColors(
                  baseColor: AppColors.surfaceVariant,
                  highlightColor: AppColors.surfaceLight,
                  child: Container(
                    width: AppSizes.videoPreviewWidth,
                    height: AppSizes.videoPreviewHeight,
                    color: AppColors.surfaceVariant,
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  width: AppSizes.videoPreviewWidth,
                  height: AppSizes.videoPreviewHeight,
                  color: AppColors.surfaceVariant,
                  child: const Icon(Icons.music_note, color: AppColors.textTertiary),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    videoInfo.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.tileTitle.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    videoInfo.channelName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _chip(Icons.access_time, videoInfo.formattedDuration),
                      const SizedBox(width: AppSpacing.sm),
                      _chip(Icons.audiotrack, 'Audio'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppSizes.iconXxs, color: AppColors.primaryLight),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.primaryLight,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// [VideoPreviewCard] 로딩 중 표시되는 스켈레톤 Shimmer 위젯.
class VideoPreviewShimmer extends StatelessWidget {
  const VideoPreviewShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Shimmer.fromColors(
          baseColor: AppColors.surfaceVariant,
          highlightColor: AppColors.surfaceLight,
          child: Row(
            children: [
              Container(
                width: AppSizes.videoPreviewWidth,
                height: AppSizes.videoPreviewHeight,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 14, color: AppColors.surfaceVariant),
                    const SizedBox(height: 6),
                    Container(height: 14, width: AppSizes.videoPreviewWidth, color: AppColors.surfaceVariant),
                    const SizedBox(height: 6),
                    Container(height: 12, width: AppSizes.thumbnailXl, color: AppColors.surfaceVariant),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
