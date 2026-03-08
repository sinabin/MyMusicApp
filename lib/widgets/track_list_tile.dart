import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/download_item.dart';
import '../theme/app_colors.dart';
import '../utils/format_utils.dart';

/// 곡 목록 공통 타일 위젯.
///
/// 썸네일·제목·아티스트·길이를 표시하며, 탭→재생, 점 메뉴→큐 추가 지원.
/// 큐 화면 등에서 재활용.
class TrackListTile extends StatelessWidget {
  final DownloadItem item;
  final VoidCallback? onTap;
  final VoidCallback? onAddToQueue;
  final bool isCurrentTrack;
  final bool isFavorite;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onAddToPlaylist;

  const TrackListTile({
    super.key,
    required this.item,
    this.onTap,
    this.onAddToQueue,
    this.isCurrentTrack = false,
    this.isFavorite = false,
    this.onToggleFavorite,
    this.onAddToPlaylist,
  });

  @override
  Widget build(BuildContext context) {
    final title = item.fileName.endsWith('.m4a')
        ? item.fileName.substring(0, item.fileName.length - 4)
        : item.fileName;
    final artist = item.artistName ?? item.channelName ?? '';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isCurrentTrack
              ? AppColors.primarySurface
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // 썸네일
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 44,
                height: 44,
                child: _buildThumbnail(),
              ),
            ),
            const SizedBox(width: 12),
            // 곡 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isCurrentTrack
                          ? AppColors.primaryLight
                          : AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (artist.isNotEmpty) artist,
                      if (item.duration != null)
                        FormatUtils.duration(item.duration!),
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            // 즐겨찾기 버튼
            if (onToggleFavorite != null)
              IconButton(
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite
                      ? AppColors.error
                      : AppColors.textSecondary,
                  size: 20,
                ),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  onToggleFavorite?.call();
                },
                tooltip: 'Favorite',
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                padding: EdgeInsets.zero,
              ),
            // 점 메뉴
            if (onAddToQueue != null || onAddToPlaylist != null)
              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                color: AppColors.surfaceVariant,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onSelected: (value) {
                  switch (value) {
                    case 'add_to_queue':
                      onAddToQueue?.call();
                    case 'add_to_playlist':
                      onAddToPlaylist?.call();
                  }
                },
                itemBuilder: (context) => [
                  if (onAddToQueue != null)
                    const PopupMenuItem(
                      value: 'add_to_queue',
                      child: Row(
                        children: [
                          Icon(Icons.queue_music, size: 20,
                              color: AppColors.textSecondary),
                          SizedBox(width: 12),
                          Text('Add to Queue',
                              style: TextStyle(color: AppColors.textPrimary)),
                        ],
                      ),
                    ),
                  if (onAddToPlaylist != null)
                    const PopupMenuItem(
                      value: 'add_to_playlist',
                      child: Row(
                        children: [
                          Icon(Icons.playlist_add, size: 20,
                              color: AppColors.textSecondary),
                          SizedBox(width: 12),
                          Text('Add to Playlist',
                              style: TextStyle(color: AppColors.textPrimary)),
                        ],
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
      ),
    );
  }

  /// 로컬 파일 경로면 [Image.file], URL이면 [CachedNetworkImage] 반환.
  Widget _buildThumbnail() {
    final url = item.thumbnailUrl;
    if (url == null) return _placeholderIcon();
    if (url.startsWith('/')) {
      return Image.file(
        File(url),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _placeholderIcon(),
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (_, _) => _placeholderIcon(),
      errorWidget: (_, _, _) => _placeholderIcon(),
    );
  }

  Widget _placeholderIcon() {
    return Container(
      color: AppColors.primarySurface,
      child: const Icon(
        Icons.music_note,
        color: AppColors.primaryLight,
        size: 22,
      ),
    );
  }
}
