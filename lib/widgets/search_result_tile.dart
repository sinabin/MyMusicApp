import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../models/video_info.dart';
import '../theme/app_colors.dart';

/// 검색 결과 항목을 표시하는 타일 위젯.
///
/// 썸네일·제목·채널·재생 시간을 표시하며, 탭 영역과 다운로드 버튼 영역을 분리.
/// [SearchScreen]의 결과 목록에서 사용.
class SearchResultTile extends StatelessWidget {
  /// 표시할 영상 정보.
  final VideoInfo videoInfo;

  /// 타일 본체(썸네일+텍스트) 탭 콜백.
  final VoidCallback? onTap;

  /// 다운로드 아이콘 탭 콜백.
  final VoidCallback? onDownload;

  /// 다운로드 진행 중 여부 (이 영상).
  final bool isDownloading;

  /// 다운로드 비활성화 여부 (다른 영상 다운로드 중).
  final bool downloadDisabled;

  const SearchResultTile({
    super.key,
    required this.videoInfo,
    this.onTap,
    this.onDownload,
    this.isDownloading = false,
    this.downloadDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
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
                    _buildThumbnail(),
                    const SizedBox(width: 12),
                    Expanded(child: _buildInfo()),
                  ],
                ),
              ),
            ),
          ),
          // 다운로드 버튼 영역
          _buildDownloadButton(),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildThumbnail() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 100,
        height: 56,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: videoInfo.thumbnailUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Shimmer.fromColors(
                baseColor: AppColors.surfaceVariant,
                highlightColor: AppColors.surfaceLight,
                child: Container(color: AppColors.surfaceVariant),
              ),
              errorWidget: (context, url, error) => Container(
                color: AppColors.surfaceVariant,
                child: const Icon(
                  Icons.music_note,
                  color: AppColors.textTertiary,
                  size: 20,
                ),
              ),
            ),
            // 재생 시간 배지
            if (videoInfo.duration != Duration.zero)
              Positioned(
                right: 4,
                bottom: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(4),
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

  Widget _buildInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          videoInfo.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          videoInfo.channelName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildDownloadButton() {
    if (isDownloading) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primary,
          ),
        ),
      );
    }

    return IconButton(
      icon: Icon(
        Icons.download_rounded,
        color: downloadDisabled
            ? AppColors.textTertiary.withValues(alpha: 0.4)
            : AppColors.primaryLight,
        size: 22,
      ),
      onPressed: downloadDisabled ? null : onDownload,
      splashRadius: 20,
    );
  }
}
