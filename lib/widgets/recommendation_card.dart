import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/recommendation.dart';
import '../theme/app_colors.dart';

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
    return Dismissible(
      key: ValueKey(recommendation.videoId),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.not_interested, color: AppColors.error),
            SizedBox(height: 4),
            Text(
              '관심 없음',
              style: TextStyle(color: AppColors.error, fontSize: 11),
            ),
          ],
        ),
      ),
      onDismissed: (_) => onDismiss?.call(),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Row(
          children: [
            // 썸네일
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 80,
                height: 56,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: recommendation.thumbnailUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, _) => Container(
                        color: AppColors.surfaceVariant,
                        child: const Icon(
                          Icons.music_note,
                          color: AppColors.textTertiary,
                          size: 24,
                        ),
                      ),
                      errorWidget: (_, _, _) => Container(
                        color: AppColors.surfaceVariant,
                        child: const Icon(
                          Icons.music_note,
                          color: AppColors.textTertiary,
                          size: 24,
                        ),
                      ),
                    ),
                    // 재생 시간 오버레이
                    if (recommendation.duration != null)
                      Positioned(
                        right: 4,
                        bottom: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _formatDuration(recommendation.duration!),
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
            const SizedBox(width: 12),
            // 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recommendation.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    recommendation.channelName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      recommendation.reason,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.primaryLight,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // 다운로드 버튼
            IconButton(
              icon: isDownloading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    )
                  : const Icon(
                      Icons.download_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
              onPressed: isDownloading ? null : onDownload,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
          ],
        ),
      ),
      ),
    );
  }

  /// "M:SS" 또는 "H:MM:SS" 형식의 재생 시간 문자열 반환.
  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
