import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../models/download_item.dart';
import '../models/playlist_item.dart';
import '../providers/history_provider.dart';
import '../providers/player_provider.dart';
import '../providers/playlist_provider.dart';
import '../providers/settings_provider.dart';
import '../services/file_service.dart';
import '../theme/app_colors.dart';
import '../utils/format_utils.dart';
import '../widgets/add_to_playlist_sheet.dart';
import '../widgets/playlist_mosaic_art.dart';
import '../widgets/track_list_tile.dart';

/// 플레이리스트 상세 화면.
///
/// 모자이크 아트·곡 목록 표시, 순서 변경·곡 제거·이름 변경·삭제 지원.
/// Play All·Shuffle 버튼으로 재생 시작.
class PlaylistDetailScreen extends StatefulWidget {
  /// 표시할 플레이리스트.
  final PlaylistItem playlist;

  const PlaylistDetailScreen({super.key, required this.playlist});

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  List<DownloadItem> _tracks = [];
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadTracks();
  }

  void _loadTracks() {
    final provider = context.read<PlaylistProvider>();
    setState(() {
      _tracks = provider.getTracksForPlaylist(widget.playlist);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: Consumer<PlaylistProvider>(
        builder: (context, provider, _) {
          _tracks = provider.getTracksForPlaylist(widget.playlist);
          final urls =
              _tracks.take(4).map((t) => t.thumbnailUrl).toList();
          final meta =
              '${FormatUtils.trackCount(_tracks.length)} · ${FormatUtils.totalDuration(_tracks)}';

          return CustomScrollView(
            slivers: [
              // AppBar with mosaic art
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                backgroundColor: AppColors.scaffoldBackground,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    widget.playlist.name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.surfaceVariant,
                          AppColors.scaffoldBackground,
                        ],
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 60),
                          PlaylistMosaicArt(
                            thumbnailUrls: urls,
                            size: 160,
                            borderRadius: 16,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            meta,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                actions: [
                  PopupMenuButton<String>(
                    icon: const Icon(
                      Icons.more_vert,
                      color: AppColors.textSecondary,
                    ),
                    color: AppColors.surfaceVariant,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onSelected: (value) {
                      switch (value) {
                        case 'rename':
                          _showRenameDialog(context, provider);
                        case 'delete':
                          _showDeleteDialog(context, provider);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'rename',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20,
                                color: AppColors.textSecondary),
                            SizedBox(width: 12),
                            Text('Rename',
                                style: TextStyle(
                                    color: AppColors.textPrimary)),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20,
                                color: AppColors.error),
                            SizedBox(width: 12),
                            Text('Delete',
                                style: TextStyle(color: AppColors.error)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Play All / Shuffle
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ElevatedButton.icon(
                            onPressed: _tracks.isEmpty
                                ? null
                                : () {
                                    context
                                        .read<PlayerProvider>()
                                        .playAll(_tracks);
                                  },
                            icon: const Icon(Icons.play_arrow, size: 20),
                            label: const Text('Play All'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _tracks.isEmpty
                              ? null
                              : () async {
                                  final player =
                                      context.read<PlayerProvider>();
                                  await player.playAll(_tracks);
                                  await player.toggleShuffle();
                                },
                          icon: const Icon(Icons.shuffle, size: 20),
                          label: const Text('Shuffle'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side:
                                const BorderSide(color: AppColors.primary),
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Edit mode toggle
              if (_tracks.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                    child: Row(
                      children: [
                        Text(
                          '${_tracks.length} tracks',
                          style: const TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 13,
                          ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () =>
                              setState(() => _isEditing = !_isEditing),
                          icon: Icon(
                            _isEditing ? Icons.check : Icons.swap_vert,
                            size: 18,
                          ),
                          label: Text(_isEditing ? 'Done' : 'Reorder'),
                          style: TextButton.styleFrom(
                            foregroundColor: _isEditing
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Track list
              if (_tracks.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.music_off,
                          color: AppColors.textTertiary,
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'This playlist is empty',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextButton.icon(
                          onPressed: () =>
                              _showAddSongsSheet(context, provider),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add Songs'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (_isEditing)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverReorderableList(
                    itemCount: _tracks.length,
                    onReorder: (oldIndex, newIndex) {
                      provider.reorderTracks(
                        widget.playlist,
                        oldIndex,
                        newIndex,
                      );
                    },
                    itemBuilder: (context, index) {
                      final item = _tracks[index];
                      return ReorderableDelayedDragStartListener(
                        key: ValueKey(
                            'reorder_${widget.playlist.id}_${item.videoId}'),
                        index: index,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Consumer<PlayerProvider>(
                            builder: (context, player, _) {
                              return Row(
                                children: [
                                  Expanded(
                                    child: TrackListTile(
                                      item: item,
                                      isCurrentTrack:
                                          player.currentTrack?.videoId ==
                                              item.videoId,
                                      onTap: () {
                                        context
                                            .read<PlayerProvider>()
                                            .playAll(
                                              _tracks,
                                              startIndex: index,
                                            );
                                      },
                                      onAddToQueue: () {
                                        context
                                            .read<PlayerProvider>()
                                            .addToQueue(item);
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content:
                                                Text('Added to queue'),
                                          ),
                                        );
                                      },
                                      isFavorite: item.isFavorite,
                                      onToggleFavorite: () {
                                        context
                                            .read<HistoryProvider>()
                                            .toggleFavorite(item);
                                      },
                                      onAddToPlaylist: () {
                                        AddToPlaylistSheet.show(
                                          context,
                                          videoId: item.videoId,
                                        );
                                      },
                                    ),
                                  ),
                                  const Icon(
                                    Icons.drag_handle,
                                    color: AppColors.textTertiary,
                                    size: 20,
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = _tracks[index];
                        return Dismissible(
                          key: ValueKey(
                              '${widget.playlist.id}_${item.videoId}'),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color:
                                  AppColors.error.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.delete,
                              color: AppColors.error,
                            ),
                          ),
                          onDismissed: (_) {
                            provider.removeTrackFromPlaylist(
                              widget.playlist,
                              item.videoId,
                            );
                          },
                          child: Consumer<PlayerProvider>(
                            builder: (context, player, _) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: TrackListTile(
                                  item: item,
                                  isCurrentTrack:
                                      player.currentTrack?.videoId ==
                                          item.videoId,
                                  onTap: () {
                                    context
                                        .read<PlayerProvider>()
                                        .playAll(
                                          _tracks,
                                          startIndex: index,
                                        );
                                  },
                                  onAddToQueue: () {
                                    context
                                        .read<PlayerProvider>()
                                        .addToQueue(item);
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      const SnackBar(
                                        content:
                                            Text('Added to queue'),
                                      ),
                                    );
                                  },
                                  isFavorite: item.isFavorite,
                                  onToggleFavorite: () {
                                    context
                                        .read<HistoryProvider>()
                                        .toggleFavorite(item);
                                  },
                                  onAddToPlaylist: () {
                                    AddToPlaylistSheet.show(
                                      context,
                                      videoId: item.videoId,
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                        );
                      },
                      childCount: _tracks.length,
                    ),
                  ),
                ),

              // Add Songs button
              if (_tracks.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    child: TextButton.icon(
                      onPressed: () =>
                          _showAddSongsSheet(context, provider),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Songs'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                      ),
                    ),
                  ),
                ),

              // Bottom padding
              const SliverToBoxAdapter(
                child: SizedBox(height: 32),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showRenameDialog(BuildContext context, PlaylistProvider provider) {
    final controller = TextEditingController(text: widget.playlist.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Rename Playlist',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surfaceVariant,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                provider.renamePlaylist(widget.playlist, name);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, PlaylistProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Delete Playlist',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Are you sure you want to delete "${widget.playlist.name}"?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.deletePlaylist(widget.playlist);
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddSongsSheet(
    BuildContext context,
    PlaylistProvider provider,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddSongsSheet(
        playlist: widget.playlist,
        provider: provider,
        savePath: context.read<SettingsProvider>().settings.savePath,
      ),
    );
  }
}

/// DB 조회 및 디렉토리 스캔으로 추가 가능한 곡을 표시하는 바텀시트.
///
/// DB 미등록 m4a 파일은 자동 등록 후 표시. 개별 선택·전체 선택 지원.
class _AddSongsSheet extends StatefulWidget {
  final PlaylistItem playlist;
  final PlaylistProvider provider;
  final String savePath;

  const _AddSongsSheet({
    required this.playlist,
    required this.provider,
    required this.savePath,
  });

  @override
  State<_AddSongsSheet> createState() => _AddSongsSheetState();
}

class _AddSongsSheetState extends State<_AddSongsSheet> {
  List<DownloadItem> _available = [];
  bool _loading = true;
  final Set<String> _selectedIds = {};

  bool get _allSelected =>
      _available.isNotEmpty && _selectedIds.length == _available.length;

  @override
  void initState() {
    super.initState();
    _loadAvailableSongs();
  }

  /// DB 조회 + 디렉토리 스캔 병행으로 추가 가능한 곡 로드.
  ///
  /// [Permission.manageExternalStorage] 확보 후 디렉토리를 스캔하여
  /// DB 미등록 m4a 파일을 자동 등록. 권한 미확보 시 DB 항목만 표시.
  Future<void> _loadAvailableSongs() async {
    final provider = widget.provider;
    final existingIds = widget.playlist.trackVideoIds.toSet();

    // 1차: DB에서 플레이리스트 미포함 곡
    final results = provider.getAvailableTracks(widget.playlist);

    // 2차: 저장소 전체 접근 권한 확보 후 디렉토리 스캔
    if (widget.savePath.isNotEmpty) {
      try {
        final hasAccess = await _ensureStorageAccess();
        if (hasAccess) {
          final dir = Directory(widget.savePath);
          if (dir.existsSync()) {
            final trackedPaths = provider.allTrackedPaths;
            final files = dir
                .listSync()
                .whereType<File>()
                .where((f) => f.path.toLowerCase().endsWith('.m4a'))
                .where((f) => !trackedPaths.contains(f.path))
                .toList()
              ..sort((a, b) =>
                  b.statSync().modified.compareTo(a.statSync().modified));

            final fileService = FileService();
            for (final file in files) {
              final fileName = file.path.split('/').last;
              final stat = file.statSync();
              final thumbPath =
                  await fileService.getLocalThumbnailPath(fileName);
              final newItem = DownloadItem(
                fileName: fileName,
                filePath: file.path,
                fileSize: stat.size,
                downloadDate: stat.modified,
                videoId: 'local_${file.path.hashCode.toRadixString(36)}',
                thumbnailUrl: thumbPath,
              );
              await provider.registerDownloadItem(newItem);
              if (!existingIds.contains(newItem.videoId)) {
                results.add(newItem);
              }
            }
          }
        }
      } catch (e) {
        debugPrint('[AddSongs] Directory scan failed: $e');
      }
    }

    if (mounted) {
      setState(() {
        _available = results;
        _loading = false;
      });
    }
  }

  /// Android 11+ 저장소 전체 접근 권한 확보.
  ///
  /// 이미 허용됐으면 즉시 true, 아니면 시스템 설정 화면으로 유도.
  Future<bool> _ensureStorageAccess() async {
    if (Platform.isAndroid) {
      final status = await Permission.manageExternalStorage.status;
      if (status.isGranted) return true;
      final result = await Permission.manageExternalStorage.request();
      return result.isGranted;
    }
    return true;
  }

  void _toggleAll() {
    setState(() {
      if (_allSelected) {
        _selectedIds.clear();
      } else {
        _selectedIds
          ..clear()
          ..addAll(_available.map((e) => e.videoId));
      }
    });
  }

  void _toggle(String videoId) {
    setState(() {
      if (!_selectedIds.remove(videoId)) {
        _selectedIds.add(videoId);
      }
    });
  }

  Future<void> _addSelected() async {
    if (_selectedIds.isEmpty) return;
    await widget.provider.addTracksToPlaylist(
      widget.playlist,
      _selectedIds.toList(),
    );
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_selectedIds.length} songs added to ${widget.playlist.name}',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 드래그 핸들
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textTertiary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // 헤더
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Add Songs',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (!_loading && _available.isNotEmpty)
                  TextButton(
                    onPressed: _toggleAll,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(_allSelected ? 'Deselect All' : 'Select All'),
                  ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          // 경로 표시
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                const Icon(
                  Icons.folder_outlined,
                  color: AppColors.textTertiary,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    widget.savePath,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Divider(color: AppColors.divider, height: 1),
          // 곡 목록
          Flexible(
            child: _loading
                ? const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  )
                : _available.isEmpty
                    ? Padding(
                        padding: EdgeInsets.fromLTRB(
                            32, 32, 32, 32 + bottomPadding),
                        child: const Text(
                          'No songs available to add',
                          style: TextStyle(color: AppColors.textTertiary),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        itemCount: _available.length,
                        itemBuilder: (context, index) {
                          final item = _available[index];
                          final selected =
                              _selectedIds.contains(item.videoId);
                          return _SelectableTrackTile(
                            item: item,
                            selected: selected,
                            onTap: () => _toggle(item.videoId),
                          );
                        },
                      ),
          ),
          // 추가 버튼
          if (!_loading && _available.isNotEmpty)
            Container(
              padding: EdgeInsets.fromLTRB(24, 12, 24, 12 + bottomPadding),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.divider),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                child: AnimatedOpacity(
                  opacity: _selectedIds.isEmpty ? 0.5 : 1.0,
                  duration: const Duration(milliseconds: 150),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: _selectedIds.isNotEmpty
                          ? AppColors.primaryGradient
                          : null,
                      color: _selectedIds.isEmpty
                          ? AppColors.surfaceVariant
                          : null,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ElevatedButton(
                      onPressed:
                          _selectedIds.isEmpty ? null : _addSelected,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        disabledBackgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        disabledForegroundColor: AppColors.textTertiary,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _selectedIds.isEmpty
                            ? 'Select songs to add'
                            : 'Add ${_selectedIds.length} Songs',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 체크박스가 포함된 곡 선택 타일.
class _SelectableTrackTile extends StatelessWidget {
  final DownloadItem item;
  final bool selected;
  final VoidCallback onTap;

  const _SelectableTrackTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final title = item.fileName.endsWith('.m4a')
        ? item.fileName.substring(0, item.fileName.length - 4)
        : item.fileName;
    final artist = item.artistName ?? item.channelName ?? '';

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: selected
            ? AppColors.primarySurface.withValues(alpha: 0.3)
            : Colors.transparent,
        child: Row(
          children: [
            // 체크박스
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked,
              color: selected ? AppColors.primary : AppColors.textTertiary,
              size: 22,
            ),
            const SizedBox(width: 12),
            // 썸네일
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 44,
                height: 44,
                child: item.thumbnailUrl != null
                    ? Image.network(
                        item.thumbnailUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _placeholder(),
                      )
                    : _placeholder(),
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
                      color: selected
                          ? AppColors.primaryLight
                          : AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (artist.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
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
