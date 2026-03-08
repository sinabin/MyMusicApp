import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/download_item.dart';
import '../theme/app_colors.dart';
import '../utils/format_utils.dart';

/// 다운로드 기록 목록의 개별 항목을 표시하는 타일 위젯.
///
/// 파일명·크기·날짜 정보와 재생·큐 추가·스와이프 삭제 기능을 제공.
/// [DownloadItem] 데이터를 받아 렌더링.
class DownloadHistoryTile extends StatelessWidget {
  final DownloadItem item;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;
  final VoidCallback? onAddToQueue;
  final bool isFavorite;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onAddToPlaylist;

  const DownloadHistoryTile({
    super.key,
    required this.item,
    this.onDelete,
    this.onTap,
    this.onAddToQueue,
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

    return Dismissible(
      key: ValueKey(item.filePath),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: AppColors.error),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete'),
            content: const Text('Remove this download?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: AppColors.error),
                ),
              ),
            ],
          ),
        ) ?? false;
      },
      onDismissed: (_) => onDelete?.call(),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                  width: 40,
                  height: 40,
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
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (artist.isNotEmpty) artist,
                        FormatUtils.fileSize(item.fileSize),
                        FormatUtils.date(item.downloadDate),
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
              // 컨텍스트 메뉴
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
                    case 'favorite':
                      onToggleFavorite?.call();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'add_to_queue',
                    child: Row(
                      children: [
                        Icon(Icons.queue_music, size: 20,
                            color: AppColors.textSecondary),
                        SizedBox(width: 12),
                        Text('바로 다음에 재생',
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
                          Text('플레이리스트에 추가',
                              style: TextStyle(color: AppColors.textPrimary)),
                        ],
                      ),
                    ),
                  if (onToggleFavorite != null)
                    PopupMenuItem(
                      value: 'favorite',
                      child: Row(
                        children: [
                          Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            size: 20,
                            color: isFavorite
                                ? AppColors.error
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            isFavorite ? '좋아요 해제' : '좋아요',
                            style: const TextStyle(
                                color: AppColors.textPrimary),
                          ),
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
        size: 20,
      ),
    );
  }
}
