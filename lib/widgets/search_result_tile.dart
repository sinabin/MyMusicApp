import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../models/video_info.dart';
import '../theme/app_color_scheme.dart';
import '../theme/app_sizes.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';

/// 검색 결과 항목을 표시하는 타일 위젯.
///
/// 썸네일·제목·채널·재생 시간을 표시하며, 탭 영역과 버튼 영역을 분리.
/// 스트리밍 재생·다운로드 버튼을 개별 제공.
class SearchResultTile extends StatelessWidget {
  /// 표시할 영상 정보.
  final VideoInfo videoInfo;

  /// 타일 본체(썸네일+텍스트) 탭 콜백.
  final VoidCallback? onTap;

  /// 다운로드 아이콘 탭 콜백.
  final VoidCallback? onDownload;

  /// 스트리밍 재생 아이콘 탭 콜백.
  final VoidCallback? onStream;

  /// 다운로드 진행 중 여부 (이 영상).
  final bool isDownloading;

  /// 스트리밍 준비 중 여부 (이 영상).
  final bool isStreamLoading;

  /// 다운로드 비활성화 여부 (다른 영상 다운로드 중).
  final bool downloadDisabled;

  const SearchResultTile({
    super.key,
    required this.videoInfo,
    this.onTap,
    this.onDownload,
    this.onStream,
    this.isDownloading = false,
    this.isStreamLoading = false,
    this.downloadDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = AppColorScheme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Row(
        children: [
          // 탭 영역: 썸네일 + 텍스트
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    _buildThumbnail(context),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: _buildInfo(context)),
                  ],
                ),
              ),
            ),
          ),
          // 스트리밍 재생 버튼
          _buildStreamButton(context),
          // 다운로드 버튼
          _buildDownloadButton(context),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
    );
  }

  Widget _buildThumbnail(BuildContext context) {
    final cs = AppColorScheme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      child: SizedBox(
        width: AppSizes.searchThumbWidth,
        height: AppSizes.searchThumbHeight,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: videoInfo.thumbnailUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Shimmer.fromColors(
                baseColor: cs.surfaceVariant,
                highlightColor: cs.surfaceLight,
                child: Container(color: cs.surfaceVariant),
              ),
              errorWidget: (context, url, error) => Container(
                color: cs.surfaceVariant,
                child: Icon(
                  Icons.music_note,
                  color: cs.textTertiary,
                  size: AppSizes.iconMd,
                ),
              ),
            ),
            // 재생 시간 배지
            if (videoInfo.duration != Duration.zero)
              Positioned(
                right: AppSpacing.xs,
                bottom: AppSpacing.xs,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: AppSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(AppSpacing.xs),
                  ),
                  child: Text(
                    videoInfo.formattedDuration,
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
    );
  }

  Widget _buildInfo(BuildContext context) {
    final cs = AppColorScheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          videoInfo.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.bodySmall.copyWith(height: 1.3),
        ),
        const SizedBox(height: 3),
        Text(
          videoInfo.channelName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: cs.textSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildStreamButton(BuildContext context) {
    final cs = AppColorScheme.of(context);
    if (isStreamLoading) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: SizedBox(
          width: AppSizes.indicatorSm,
          height: AppSizes.indicatorSm,
          child: CircularProgressIndicator(
            strokeWidth: AppSizes.strokeWidth,
            color: cs.primaryLight,
          ),
        ),
      );
    }

    return IconButton(
      icon: Icon(
        Icons.play_circle_outline,
        color: cs.primaryLight,
        size: AppSizes.iconMl,
      ),
      onPressed: onStream,
      splashRadius: AppSpacing.xl,
      tooltip: 'Stream',
    );
  }

  Widget _buildDownloadButton(BuildContext context) {
    final cs = AppColorScheme.of(context);
    if (isDownloading) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: SizedBox(
          width: AppSizes.indicatorSm,
          height: AppSizes.indicatorSm,
          child: CircularProgressIndicator(
            strokeWidth: AppSizes.strokeWidth,
            color: cs.primary,
          ),
        ),
      );
    }

    return IconButton(
      icon: Icon(
        Icons.download_rounded,
        color: downloadDisabled
            ? cs.textTertiary.withValues(alpha: 0.4)
            : cs.primaryLight,
        size: AppSizes.iconMl,
      ),
      onPressed: downloadDisabled ? null : onDownload,
      splashRadius: AppSpacing.xl,
    );
  }
}
