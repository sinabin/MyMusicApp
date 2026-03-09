import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/download_item.dart';
import '../providers/history_provider.dart';
import '../services/file_service.dart';
import '../providers/playback_history_provider.dart';
import '../providers/player_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_color_scheme.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/add_to_playlist_sheet.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/track_list_tile.dart';

/// 최근 재생 기록 화면.
///
/// 시간 구간별로 그룹화하여 표시 (Today, Yesterday, This Week, Earlier).
/// Clear 버튼으로 전체 기록 삭제 가능.
class RecentPlaysScreen extends StatelessWidget {
  const RecentPlaysScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = AppColorScheme.of(context);
    return Scaffold(
      backgroundColor: cs.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: cs.scaffoldBackground,
        title: Text(
          'Recent Plays',
          style: AppTextStyles.sectionHeader,
        ),
        actions: [
          Consumer<PlaybackHistoryProvider>(
            builder: (context, provider, _) {
              return IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  color: cs.textSecondary,
                ),
                onPressed: provider.recentCount == 0
                    ? null
                    : () => _showClearDialog(context, provider),
              );
            },
          ),
        ],
      ),
      body: Consumer<PlaybackHistoryProvider>(
        builder: (context, playback, _) {
          final grouped = playback.getGroupedRecentTracks();
          if (grouped.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.history,
              title: 'No plays yet',
              description: 'Songs you play will appear here',
            );
          }

          // 섹션 헤더와 트랙을 하나의 리스트로 평탄화하여 O(1) 인덱싱 지원.
          final sections = grouped.entries.toList();
          final flatEntries = <_FlatEntry>[];
          final allTracks = <DownloadItem>[];
          for (final section in sections) {
            flatEntries.add(_FlatEntry.header(section.key));
            for (final track in section.value) {
              flatEntries.add(_FlatEntry.track(track));
              allTracks.add(track);
            }
          }

          return Selector<PlayerProvider, String?>(
            selector: (_, p) => p.currentTrack?.videoId,
            builder: (context, currentVideoId, _) {
              return ListView.builder(
                padding: const EdgeInsets.only(
                  left: AppSpacing.lg,
                  right: AppSpacing.lg,
                  bottom: AppSpacing.lg,
                ),
                itemCount: flatEntries.length,
                itemBuilder: (context, index) {
                  final entry = flatEntries[index];
                  if (entry.isHeader) {
                    return Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.sm),
                      child: Text(
                        entry.headerLabel!.toUpperCase(),
                        style: AppTextStyles.caption.copyWith(
                          color: cs.textTertiary,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    );
                  }
                  final item = entry.item!;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: TrackListTile(
                      item: item,
                      fileService: context.read<FileService>(),
                      isCurrentTrack: currentVideoId == item.videoId,
                      onTap: () {
                        final playAll = context
                            .read<SettingsProvider>()
                            .settings
                            .playAllOnTap;
                        if (playAll) {
                          final idx = allTracks.indexOf(item);
                          context
                              .read<PlayerProvider>()
                              .playAll(allTracks, startIndex: idx);
                        } else {
                          context.read<PlayerProvider>().playTrack(item);
                        }
                      },
                      onAddToQueue: () {
                        HapticFeedback.lightImpact();
                        context.read<PlayerProvider>().addToQueue(item);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Added to queue')),
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
              );
            },
          );
        },
      ),
    );
  }

  void _showClearDialog(
    BuildContext context,
    PlaybackHistoryProvider provider,
  ) {
    final cs = AppColorScheme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cs.surface,
        title: Text(
          'Clear History',
          style: TextStyle(color: cs.textPrimary),
        ),
        content: Text(
          'Are you sure you want to clear all play history?',
          style: TextStyle(color: cs.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.clearHistory();
              Navigator.pop(ctx);
            },
            child: Text(
              'Clear',
              style: TextStyle(color: cs.error),
            ),
          ),
        ],
      ),
    );
  }
}

/// 섹션 헤더 또는 트랙 항목을 나타내는 평탄화된 리스트 엔트리.
class _FlatEntry {
  /// 섹션 헤더 레이블 (헤더인 경우).
  final String? headerLabel;

  /// 트랙 항목 (트랙인 경우).
  final DownloadItem? item;

  /// 헤더 여부.
  bool get isHeader => headerLabel != null;

  const _FlatEntry.header(this.headerLabel) : item = null;
  const _FlatEntry.track(this.item) : headerLabel = null;
}
