import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/download_item.dart';
import '../providers/player_provider.dart';
import '../theme/app_colors.dart';
import 'empty_state_widget.dart';
import 'track_list_tile.dart';

/// AllSongsScreen·FavoritesScreen 공통 레이아웃 위젯.
///
/// 곡 목록을 표시하며, 정렬·즐겨찾기·현재 재생 곡 하이라이트 기능 제공.
class SongListScreen extends StatefulWidget {
  /// 화면 제목.
  final String title;

  /// 곡 목록.
  final List<DownloadItem> items;

  /// 빈 상태 위젯.
  final Widget? emptyState;

  /// AppBar actions.
  final List<Widget>? actions;

  /// 목록 상단 헤더 위젯 (Play All/Shuffle 등).
  final Widget? headerWidget;

  /// 즐겨찾기 버튼 표시 여부.
  final bool showFavoriteButton;

  /// 정렬 옵션 표시 여부.
  final bool showSortOptions;

  /// 곡 탭 콜백.
  final void Function(DownloadItem) onTap;

  /// 즐겨찾기 토글 콜백.
  final void Function(DownloadItem)? onToggleFavorite;

  /// 큐 추가 콜백.
  final void Function(DownloadItem)? onAddToQueue;

  /// 플레이리스트 추가 콜백.
  final void Function(DownloadItem)? onAddToPlaylist;

  const SongListScreen({
    super.key,
    required this.title,
    required this.items,
    this.emptyState,
    this.actions,
    this.headerWidget,
    this.showFavoriteButton = false,
    this.showSortOptions = false,
    required this.onTap,
    this.onToggleFavorite,
    this.onAddToQueue,
    this.onAddToPlaylist,
  });

  @override
  State<SongListScreen> createState() => _SongListScreenState();
}

enum _SortOption { recent, name, duration }

class _SongListScreenState extends State<SongListScreen> {
  _SortOption _sortOption = _SortOption.recent;
  _SortOption? _lastSortOption;
  List<DownloadItem>? _lastItems;
  List<DownloadItem> _cachedItems = const [];

  /// 정렬 옵션·원본 목록이 변경될 때만 재정렬하여 캐시 반환.
  List<DownloadItem> get _sortedItems {
    if (!widget.showSortOptions) return widget.items;
    if (_lastSortOption == _sortOption &&
        identical(_lastItems, widget.items)) {
      return _cachedItems;
    }
    final items = List<DownloadItem>.from(widget.items);
    switch (_sortOption) {
      case _SortOption.recent:
        items.sort((a, b) => b.downloadDate.compareTo(a.downloadDate));
      case _SortOption.name:
        items.sort((a, b) => a.fileName.compareTo(b.fileName));
      case _SortOption.duration:
        items.sort((a, b) =>
            (b.durationInMs ?? 0).compareTo(a.durationInMs ?? 0));
    }
    _lastSortOption = _sortOption;
    _lastItems = widget.items;
    _cachedItems = items;
    return _cachedItems;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.scaffoldBackground,
        title: Text(
          '${widget.title} (${widget.items.length})',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: widget.actions,
      ),
      body: widget.items.isEmpty
          ? Center(child: widget.emptyState ?? const EmptyStateWidget())
          : Consumer<PlayerProvider>(
              builder: (context, player, _) {
                final sorted = _sortedItems;
                return ListView.builder(
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 8,
                    bottom: 16,
                  ),
                  itemCount: sorted.length +
                      (widget.headerWidget != null ? 1 : 0) +
                      (widget.showSortOptions ? 1 : 0),
                  itemBuilder: (context, index) {
                    int offset = 0;

                    if (widget.headerWidget != null) {
                      if (index == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: widget.headerWidget,
                        );
                      }
                      offset++;
                    }

                    if (widget.showSortOptions) {
                      if (index == offset) {
                        return _buildSortChips();
                      }
                      offset++;
                    }

                    final itemIndex = index - offset;
                    final item = sorted[itemIndex];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: TrackListTile(
                        item: item,
                        isCurrentTrack:
                            player.currentTrack?.videoId == item.videoId,
                        onTap: () => widget.onTap(item),
                        onAddToQueue: widget.onAddToQueue != null
                            ? () => widget.onAddToQueue!(item)
                            : null,
                        isFavorite: item.isFavorite,
                        onToggleFavorite: widget.onToggleFavorite != null
                            ? () => widget.onToggleFavorite!(item)
                            : null,
                        onAddToPlaylist: widget.onAddToPlaylist != null
                            ? () => widget.onAddToPlaylist!(item)
                            : null,
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildSortChips() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          _sortChip('Recent', _SortOption.recent),
          const SizedBox(width: 8),
          _sortChip('Name', _SortOption.name),
          const SizedBox(width: 8),
          _sortChip('Duration', _SortOption.duration),
        ],
      ),
    );
  }

  Widget _sortChip(String label, _SortOption option) {
    final selected = _sortOption == option;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: selected ? AppColors.textPrimary : AppColors.textSecondary,
        ),
      ),
      selected: selected,
      onSelected: (_) => setState(() => _sortOption = option),
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.surface,
      side: BorderSide(
        color: selected ? AppColors.primary : AppColors.border,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      visualDensity: VisualDensity.compact,
    );
  }
}
