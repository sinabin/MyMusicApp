import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../models/download_item.dart';
import '../services/file_service.dart';
import '../theme/app_color_scheme.dart';
import '../theme/app_sizes.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import '../utils/format_utils.dart';

/// 곡 목록 공통 타일 위젯.
///
/// 썸네일·제목·아티스트·길이를 표시하며, 탭→재생, 점 메뉴→컨텍스트 액션,
/// 롱프레스→외부 콜백(예: 플레이리스트 제거) 지원.
/// 큐·즐겨찾기·플레이리스트 화면 등에서 재활용.
class TrackListTile extends StatelessWidget {
  final DownloadItem item;
  final VoidCallback? onTap;
  final VoidCallback? onAddToQueue;
  final bool isCurrentTrack;
  final bool isFavorite;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onAddToPlaylist;

  /// 롱프레스 시 호출할 콜백 (예: 플레이리스트에서 제거).
  final VoidCallback? onLongPress;

  /// 로컬 썸네일 조회용 [FileService].
  final FileService? fileService;

  const TrackListTile({
    super.key,
    required this.item,
    this.onTap,
    this.onAddToQueue,
    this.isCurrentTrack = false,
    this.isFavorite = false,
    this.onToggleFavorite,
    this.onAddToPlaylist,
    this.onLongPress,
    this.fileService,
  });

  /// 점 메뉴 항목 유무.
  bool get _hasMenuItems =>
      onAddToQueue != null || onAddToPlaylist != null || onToggleFavorite != null;

  @override
  Widget build(BuildContext context) {
    final cs = AppColorScheme.of(context);
    final title = item.fileName.endsWith('.m4a')
        ? item.fileName.substring(0, item.fileName.length - 4)
        : item.fileName;
    final artist = item.artistName ?? item.channelName ?? '';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress != null ? () {
          HapticFeedback.mediumImpact();
          onLongPress!();
        } : null,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
        decoration: BoxDecoration(
          color: isCurrentTrack
              ? cs.primarySurface
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Row(
          children: [
            // 썸네일
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              child: SizedBox(
                width: AppSizes.thumbnailMd,
                height: AppSizes.thumbnailMd,
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
                    style: AppTextStyles.tileTitle.copyWith(
                      color: isCurrentTrack
                          ? cs.primaryLight
                          : cs.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    [
                      if (artist.isNotEmpty) artist,
                      if (item.duration != null)
                        FormatUtils.duration(item.duration!),
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(color: cs.textTertiary),
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
                      ? cs.error
                      : cs.textSecondary,
                  size: AppSizes.iconMd,
                ),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  onToggleFavorite?.call();
                },
                tooltip: '좋아요',
                constraints: const BoxConstraints(
                  minWidth: AppSizes.touchTarget,
                  minHeight: AppSizes.touchTarget,
                ),
                padding: EdgeInsets.zero,
              ),
            // 점 메뉴 (큐·플레이리스트·좋아요)
            if (_hasMenuItems)
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
                itemBuilder: (ctx) => _buildMenuItems(ctx, includeFavorite: true),
              ),
          ],
        ),
      ),
      ),
    );
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
  ///
  /// [includeFavorite]가 true이면 즐겨찾기 토글 항목도 포함 (롱프레스 메뉴용).
  List<PopupMenuEntry<String>> _buildMenuItems(BuildContext context, {bool includeFavorite = false}) {
    final cs = AppColorScheme.of(context);
    final l = L.of(context)!;
    return [
      if (onAddToQueue != null)
        PopupMenuItem(
          value: 'add_to_queue',
          child: Row(
            children: [
              Icon(Icons.queue_music, size: AppSizes.iconMd,
                  color: cs.textSecondary),
              const SizedBox(width: AppSpacing.md),
              Text(l.addToQueue,
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
              Text(l.addToPlaylist,
                  style: AppTextStyles.body),
            ],
          ),
        ),
      if (includeFavorite && onToggleFavorite != null)
        PopupMenuItem(
          value: 'toggle_favorite',
          child: Row(
            children: [
              Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                size: AppSizes.iconMd,
                color: isFavorite ? cs.error : cs.textSecondary,
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                isFavorite ? l.unfavorite : l.favorite,
                style: AppTextStyles.body,
              ),
            ],
          ),
        ),
    ];
  }

  /// 로컬 파일 우선, 네트워크 URL 폴백으로 썸네일 반환.
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

    final localPath = fileService?.getLocalThumbnailPathSync(item.fileName);
    if (localPath != null) {
      return Image.file(
        File(localPath),
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
        size: AppSizes.iconMl,
      ),
    );
  }
}
