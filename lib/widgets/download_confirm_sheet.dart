import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../models/video_info.dart';
import '../providers/download_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';

/// 다운로드·스트리밍 확인 바텀 시트.
///
/// 검색 결과의 미리보기 정보와 다운로드·스트리밍 버튼을 표시.
/// [onStream]이 null이면 스트리밍 버튼을 숨김.
class DownloadConfirmSheet extends StatelessWidget {
  final VideoInfo videoInfo;
  final VoidCallback onDownload;
  final VoidCallback? onStream;

  const DownloadConfirmSheet({
    super.key,
    required this.videoInfo,
    required this.onDownload,
    this.onStream,
  });

  /// 바텀 시트를 표시하는 헬퍼.
  static void show(
    BuildContext context, {
    required VideoInfo videoInfo,
    required VoidCallback onDownload,
    VoidCallback? onStream,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXl)),
      ),
      builder: (_) => DownloadConfirmSheet(
        videoInfo: videoInfo,
        onDownload: onDownload,
        onStream: onStream,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.xl,
        AppSpacing.xl + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 핸들 바
          Container(
            width: AppSizes.handleWidth,
            height: AppSizes.handleHeight,
            decoration: BoxDecoration(
              color: AppColors.textTertiary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // 영상 정보
          _buildVideoInfo(),
          const SizedBox(height: AppSpacing.xxl),

          // 스트리밍 재생 버튼
          if (onStream != null) ...[
            _buildStreamButton(),
            const SizedBox(height: AppSpacing.md),
          ],

          // 다운로드 버튼
          _buildDownloadButton(),
        ],
      ),
    );
  }

  /// 영상 썸네일·제목·채널·길이 표시.
  Widget _buildVideoInfo() {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: SizedBox(
            width: AppSizes.videoPreviewWidth,
            height: AppSizes.videoPreviewHeight,
            child: CachedNetworkImage(
              imageUrl: videoInfo.thumbnailUrl,
              fit: BoxFit.cover,
              placeholder: (_, _) => Shimmer.fromColors(
                baseColor: AppColors.surfaceVariant,
                highlightColor: AppColors.surfaceLight,
                child: Container(color: AppColors.surfaceVariant),
              ),
              errorWidget: (_, _, _) => Container(
                color: AppColors.surfaceVariant,
                child: const Icon(
                  Icons.music_note,
                  color: AppColors.textTertiary,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                videoInfo.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.tileTitle
                    .copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                videoInfo.channelName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textSecondary),
              ),
              if (videoInfo.duration != Duration.zero) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  videoInfo.formattedDuration,
                  style: AppTextStyles.caption,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// 스트리밍 재생 버튼.
  Widget _buildStreamButton() {
    return Semantics(
      button: true,
      label: '스트리밍 재생',
      child: SizedBox(
      width: double.infinity,
      height: AppSizes.searchBarHeight,
      child: Material(
        borderRadius: BorderRadius.circular(AppSizes.searchBarHeight / 2),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSizes.searchBarHeight / 2),
          onTap: () {
            HapticFeedback.mediumImpact();
            onStream?.call();
          },
          child: Ink(
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius:
                  BorderRadius.circular(AppSizes.searchBarHeight / 2),
            ),
            child: const Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.play_circle_outline,
                    color: Colors.white,
                    size: AppSizes.iconMl,
                  ),
                  SizedBox(width: AppSpacing.sm),
                  Text(
                    'Stream',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
    );
  }

  /// 다운로드 버튼 ([DownloadProvider] 상태에 따라 비활성화).
  Widget _buildDownloadButton() {
    return Selector<DownloadProvider, bool>(
      selector: (_, p) => p.status.isActive,
      builder: (context, isActive, _) {
        return SizedBox(
          width: double.infinity,
          height: AppSizes.searchBarHeight,
          child: Material(
            borderRadius: BorderRadius.circular(AppSizes.searchBarHeight / 2),
            child: InkWell(
              borderRadius:
                  BorderRadius.circular(AppSizes.searchBarHeight / 2),
              onTap: isActive
                  ? null
                  : () {
                      HapticFeedback.mediumImpact();
                      onDownload();
                    },
              child: Ink(
                decoration: BoxDecoration(
                  border: isActive
                      ? null
                      : Border.all(color: AppColors.primary, width: 1.5),
                  color: isActive ? AppColors.surfaceVariant : null,
                  borderRadius:
                      BorderRadius.circular(AppSizes.searchBarHeight / 2),
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.download_rounded,
                        color: isActive
                            ? AppColors.textTertiary
                            : AppColors.primary,
                        size: AppSizes.iconMl,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        isActive
                            ? 'Download in progress...'
                            : 'Download Audio',
                        style: TextStyle(
                          color: isActive
                              ? AppColors.textTertiary
                              : AppColors.primary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
