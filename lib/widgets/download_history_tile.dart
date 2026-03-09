import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/download_item.dart';
import '../theme/app_color_scheme.dart';
import '../theme/app_sizes.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
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
    final cs = AppColorScheme.of(context);
    final title = item.fileName.endsWith('.m4a')
        ? item.fileName.substring(0, item.fileName.length - 4)
        : item.fileName;
    final artist = item.artistName ?? item.channelName ?? '';

    return Dismissible(
      key: ValueKey(item.filePath),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.xl),
        decoration: BoxDecoration(
          color: cs.error.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Icon(Icons.delete, color: cs.error),
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
                child: Text(
                  'Delete',
                  style: TextStyle(color: cs.error),
                ),
              ),
            ],
          ),
        ) ?? false;
      },
      onDismissed: (_) => onDelete?.call(),
      child: InkWell(
        onTap: onTap,
        onLongPress: () => _showContextMenu(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: cs.border, width: 1),
          ),
          child: Row(
            children: [
              // 썸네일
              ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                child: SizedBox(
                  width: AppSizes.thumbnailSm,
                  height: AppSizes.thumbnailSm,
                  child: _buildThumbnail(context),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              // 곡 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.tileTitle,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      [
                        if (artist.isNotEmpty) artist,
                        FormatUtils.fileSize(item.fileSize),
                        FormatUtils.date(item.downloadDate),
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption
                          .copyWith(color: cs.textTertiary),
                    ),
                  ],
                ),
              ),
              // 컨텍스트 메뉴
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  color: cs.textSecondary,
                  size: AppSizes.iconMd,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: AppSizes.touchTarget,
                  minHeight: AppSizes.touchTarget,
                ),
                color: cs.surfaceVariant,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                onSelected: _onMenuSelected,
                itemBuilder: (_) => _buildMenuItems(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 롱프레스 시 컨텍스트 메뉴 표시.
  void _showContextMenu(BuildContext context) {
    final cs = AppColorScheme.of(context);
    HapticFeedback.mediumImpact();
    final box = context.findRenderObject() as RenderBox;
    final offset = box.localToGlobal(Offset.zero);

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx + box.size.width * 0.5,
        offset.dy,
        offset.dx + box.size.width,
        offset.dy + box.size.height,
      ),
      color: cs.surfaceVariant,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      items: _buildMenuItems(context),
    ).then((value) {
      if (value != null) _onMenuSelected(value);
    });
  }

  /// 메뉴 항목 선택 처리.
  void _onMenuSelected(String value) {
    switch (value) {
      case 'add_to_queue':
        onAddToQueue?.call();
      case 'add_to_playlist':
        onAddToPlaylist?.call();
      case 'toggle_favorite':
        HapticFeedback.lightImpact();
        onToggleFavorite?.call();
    }
  }

  /// 팝업 메뉴 항목 빌드.
  List<PopupMenuEntry<String>> _buildMenuItems(BuildContext context) {
    final cs = AppColorScheme.of(context);
    return [
      PopupMenuItem(
        value: 'add_to_queue',
        child: Row(
          children: [
            Icon(Icons.queue_music, size: AppSizes.iconMd,
                color: cs.textSecondary),
            const SizedBox(width: AppSpacing.md),
            Text('바로 다음에 재생',
                style: AppTextStyles.body),
          ],
        ),
      ),
      if (onAddToPlaylist != null)
        PopupMenuItem(
          value: 'add_to_playlist',
          child: Row(
            children: [
              Icon(Icons.playlist_add, size: AppSizes.iconMd,
                  color: cs.textSecondary),
              const SizedBox(width: AppSpacing.md),
              Text('플레이리스트에 추가',
                  style: AppTextStyles.body),
            ],
          ),
        ),
      if (onToggleFavorite != null)
        PopupMenuItem(
          value: 'toggle_favorite',
          child: Row(
            children: [
              Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                size: AppSizes.iconMd,
                color: isFavorite
                    ? cs.error
                    : cs.textSecondary,
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                isFavorite ? '좋아요 해제' : '좋아요',
                style: AppTextStyles.body,
              ),
            ],
          ),
        ),
    ];
  }

  /// 로컬 파일 경로면 [Image.file], URL이면 [CachedNetworkImage] 반환.
  Widget _buildThumbnail(BuildContext context) {
    final url = item.thumbnailUrl;
    if (url == null) return _placeholderIcon(context);
    if (url.startsWith('/')) {
      return Image.file(
        File(url),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _placeholderIcon(context),
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (_, _) => _placeholderIcon(context),
      errorWidget: (_, _, _) => _placeholderIcon(context),
    );
  }

  Widget _placeholderIcon(BuildContext context) {
    final cs = AppColorScheme.of(context);
    return Container(
      color: cs.primarySurface,
      child: Icon(
        Icons.music_note,
        color: cs.primaryLight,
        size: AppSizes.iconMd,
      ),
    );
  }
}
