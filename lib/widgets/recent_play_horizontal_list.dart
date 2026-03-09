import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/download_item.dart';
import '../services/file_service.dart';
import '../theme/app_color_scheme.dart';
import '../theme/app_sizes.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';

/// 최근 재생 곡을 가로 스크롤로 표시하는 위젯.
///
/// [HomeScreen]의 "Recently Played" 섹션에서 사용.
/// 최대 10곡까지 표시.
class RecentPlayHorizontalList extends StatelessWidget {
  /// 표시할 곡 목록.
  final List<DownloadItem> tracks;

  /// 현재 재생 중인 곡.
  final DownloadItem? currentTrack;

  /// 곡 탭 콜백.
  final void Function(DownloadItem) onTap;

  /// 로컬 썸네일 조회용 [FileService].
  final FileService? fileService;

  const RecentPlayHorizontalList({
    super.key,
    required this.tracks,
    this.currentTrack,
    required this.onTap,
    this.fileService,
  });

  @override
  Widget build(BuildContext context) {
    final cs = AppColorScheme.of(context);
    final items = tracks.take(10).toList();
    return SizedBox(
      height: AppSizes.recentPlayListHeight,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final isCurrent = currentTrack?.videoId == item.videoId;
          final title = item.fileName.endsWith('.m4a')
              ? item.fileName.substring(0, item.fileName.length - 4)
              : item.fileName;
          final artist = item.artistName ?? item.channelName ?? '';

          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              onTap: () => onTap(item),
              child: Padding(
                padding: EdgeInsets.only(right: index < items.length - 1 ? 10 : 0),
                child: SizedBox(
                  width: AppSizes.recentPlayCardWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: AppSizes.thumbnailXxl,
                        height: AppSizes.thumbnailXxl,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                          border: isCurrent
                              ? Border.all(color: cs.primary, width: 2)
                              : null,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(
                            isCurrent ? 10 : AppTheme.radiusMd,
                          ),
                          child: _buildThumbnail(context, item),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isCurrent
                              ? cs.primaryLight
                              : cs.textPrimary,
                          fontSize: 12,
                        ),
                      ),
                      if (artist.isNotEmpty)
                        Text(
                          artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: cs.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// 로컬 파일 우선, 네트워크 URL 폴백으로 썸네일 반환.
  Widget _buildThumbnail(BuildContext context, DownloadItem item) {
    final url = item.thumbnailUrl;
    if (url == null) return _placeholder(context);

    // 로컬 경로(DownloadItem에 저장된 경우)
    if (url.startsWith('/')) {
      return Image.file(
        File(url),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _placeholder(context),
      );
    }

    // 기존 데이터: 로컬 썸네일 파일이 존재하면 우선 사용
    final localPath = fileService?.getLocalThumbnailPathSync(item.fileName);
    if (localPath != null) {
      return Image.file(
        File(localPath),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _placeholder(context),
      );
    }

    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      memCacheWidth: 200,
      placeholder: (_, _) => _placeholder(context),
      errorWidget: (_, _, _) => _placeholder(context),
    );
  }

  Widget _placeholder(BuildContext context) {
    final cs = AppColorScheme.of(context);
    return Container(
      color: cs.primarySurface,
      child: Icon(
        Icons.music_note,
        color: cs.primaryLight,
        size: AppSizes.iconXxl,
      ),
    );
  }
}
