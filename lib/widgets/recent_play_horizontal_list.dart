import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/download_item.dart';
import '../theme/app_colors.dart';

/// 최근 재생 곡을 가로 스크롤로 표시하는 위젯.
///
/// [LibraryScreen]의 "Recently Played" 섹션에서 사용.
/// 최대 10곡까지 표시.
class RecentPlayHorizontalList extends StatelessWidget {
  /// 표시할 곡 목록.
  final List<DownloadItem> tracks;

  /// 현재 재생 중인 곡.
  final DownloadItem? currentTrack;

  /// 곡 탭 콜백.
  final void Function(DownloadItem) onTap;

  const RecentPlayHorizontalList({
    super.key,
    required this.tracks,
    this.currentTrack,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final items = tracks.take(10).toList();
    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final isCurrent = currentTrack?.videoId == item.videoId;
          final title = item.fileName.endsWith('.m4a')
              ? item.fileName.substring(0, item.fileName.length - 4)
              : item.fileName;
          final artist = item.artistName ?? item.channelName ?? '';

          return GestureDetector(
            onTap: () => onTap(item),
            child: Padding(
              padding: EdgeInsets.only(right: index < items.length - 1 ? 10 : 0),
              child: SizedBox(
                width: 110,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: isCurrent
                            ? Border.all(color: AppColors.primary, width: 2)
                            : null,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          isCurrent ? 10 : 12,
                        ),
                        child: item.thumbnailUrl != null
                            ? CachedNetworkImage(
                                imageUrl: item.thumbnailUrl!,
                                fit: BoxFit.cover,
                                placeholder: (_, _) => _placeholder(),
                                errorWidget: (_, _, _) => _placeholder(),
                              )
                            : _placeholder(),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isCurrent
                            ? AppColors.primaryLight
                            : AppColors.textPrimary,
                        fontSize: 12,
                      ),
                    ),
                    if (artist.isNotEmpty)
                      Text(
                        artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.primarySurface,
      child: const Icon(
        Icons.music_note,
        color: AppColors.primaryLight,
        size: 32,
      ),
    );
  }
}
