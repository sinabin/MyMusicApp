import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../models/artist_node.dart';
import '../models/download_item.dart';
import '../models/recommendation.dart';
import '../models/video_info.dart';
import '../providers/artist_explorer_provider.dart';
import '../providers/download_provider.dart';
import '../providers/history_provider.dart';
import '../providers/player_provider.dart';
import '../providers/settings_provider.dart';
import '../services/youtube_service.dart';
import '../theme/app_color_scheme.dart';
import '../theme/app_durations.dart';
import '../theme/app_sizes.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';

/// 아티스트 탐색 화면.
///
/// 다운로드 이력의 아티스트를 그리드로 표시하고,
/// 선택 시 인기곡 목록과 관련 아티스트를 확장 표시.
class ArtistExplorerScreen extends StatefulWidget {
  const ArtistExplorerScreen({super.key});

  @override
  State<ArtistExplorerScreen> createState() => _ArtistExplorerScreenState();
}

class _ArtistExplorerScreenState extends State<ArtistExplorerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final history = context.read<HistoryProvider>().items;
      context.read<ArtistExplorerProvider>().loadArtists(history);
    });
  }

  /// 스트리밍 재생 시작.
  Future<void> _onStream(Recommendation rec) async {
    final yt = context.read<YouTubeService>();
    final streamUrl = await yt.getAudioStreamUrl(rec.videoId);
    if (!mounted) return;

    final streamItem = DownloadItem.streaming(
      videoId: rec.videoId,
      title: rec.title,
      streamUrl: streamUrl.toString(),
      thumbnailUrl: rec.thumbnailUrl,
      channelName: rec.channelName,
      channelId: rec.channelId,
      durationInMs: rec.duration?.inMilliseconds,
    );

    context.read<PlayerProvider>().playTrack(streamItem);
  }

  /// 다운로드 시작.
  Future<void> _onDownload(Recommendation rec) async {
    final downloadProvider = context.read<DownloadProvider>();
    if (downloadProvider.status.isActive) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('다운로드가 이미 진행 중입니다')),
        );
      }
      return;
    }

    final videoInfo = VideoInfo(
      videoId: rec.videoId,
      title: rec.title,
      channelName: rec.channelName,
      duration: rec.duration ?? Duration.zero,
      thumbnailUrl: rec.thumbnailUrl,
      channelId: rec.channelId,
    );

    final settings = context.read<SettingsProvider>().settings;
    final historyProvider = context.read<HistoryProvider>();

    final item = await downloadProvider.startDownload(
      videoInfo: videoInfo,
      savePath: settings.savePath,
    );

    if (item != null && mounted) {
      historyProvider.addItem(item);
      final cs = AppColorScheme.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle,
                  color: cs.success, size: AppSizes.iconMd),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${rec.title} 다운로드 완료',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = AppColorScheme.of(context);

    return Scaffold(
      backgroundColor: cs.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('Artists', style: AppTextStyles.sectionHeader),
      ),
      body: Consumer<ArtistExplorerProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.artists.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.people_outline,
                      color: cs.textTertiary, size: AppSizes.iconHero),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    '아티스트 정보가 없습니다',
                    style: TextStyle(color: cs.textSecondary, fontSize: 15),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '더 많은 곡을 다운로드하면 아티스트가 표시됩니다',
                    style: TextStyle(color: cs.textTertiary, fontSize: 13),
                  ),
                ],
              ),
            );
          }

          return CustomScrollView(
            slivers: [
              // Artist grid
              SliverPadding(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final artist = provider.artists[index];
                      final isSelected =
                          provider.selectedChannelId == artist.channelId;

                      return _ArtistCard(
                        artist: artist,
                        isSelected: isSelected,
                        cs: cs,
                        onTap: () {
                          if (isSelected) {
                            provider.clearSelection();
                          } else {
                            provider.loadArtistTracks(artist.channelId);
                            provider.loadRelatedArtists(artist.name);
                          }
                        },
                      ).animate().fadeIn(
                            duration: AppDurations.normal,
                            delay: Duration(
                                milliseconds: (index * AppDurations.staggerMs)
                                    .clamp(0, AppDurations.staggerMaxMs)),
                          );
                    },
                    childCount: provider.artists.length,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: AppSpacing.md,
                    crossAxisSpacing: AppSpacing.md,
                    childAspectRatio: 0.85,
                  ),
                ),
              ),

              // Selected artist tracks
              if (provider.selectedChannelId != null) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xxl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Divider(color: cs.divider),
                        const SizedBox(height: AppSpacing.md),
                        Text('인기곡', style: AppTextStyles.sectionHeader),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                    ),
                  ),
                ),
                if (provider.isLoadingTracks)
                  const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.xxl),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  )
                else if (provider.selectedTracks != null)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xxl),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final track = provider.selectedTracks![index];
                          return _TrackTile(
                            track: track,
                            cs: cs,
                            onStream: () => _onStream(track),
                            onDownload: () => _onDownload(track),
                          );
                        },
                        childCount: provider.selectedTracks!.length,
                      ),
                    ),
                  ),

                // Related artists
                if (provider.relatedArtists != null &&
                    provider.relatedArtists!.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xxl),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: AppSpacing.xl),
                          Text('관련 아티스트',
                              style: AppTextStyles.sectionHeader),
                          const SizedBox(height: AppSpacing.sm),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xxl),
                        itemCount: provider.relatedArtists!.length,
                        itemBuilder: (context, index) {
                          final related = provider.relatedArtists![index];
                          return _RelatedArtistChip(
                            artist: related,
                            cs: cs,
                            onTap: () {
                              provider
                                  .loadArtistTracks(related.channelId);
                              provider.loadRelatedArtists(related.name);
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ],

              const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.xxxl)),
            ],
          );
        },
      ),
    );
  }
}

/// 아티스트 카드 위젯.
class _ArtistCard extends StatelessWidget {
  final ArtistNode artist;
  final bool isSelected;
  final AppColorScheme cs;
  final VoidCallback onTap;

  const _ArtistCard({
    required this.artist,
    required this.isSelected,
    required this.cs,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? cs.primarySurface : cs.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: isSelected ? cs.primary : cs.border,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: cs.surfaceVariant,
              backgroundImage: artist.thumbnailUrl != null
                  ? CachedNetworkImageProvider(artist.thumbnailUrl!)
                  : null,
              child: artist.thumbnailUrl == null
                  ? Icon(Icons.person,
                      color: cs.textTertiary, size: AppSizes.iconLg)
                  : null,
            ),
            const SizedBox(height: AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: Text(
                artist.name,
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: cs.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
            Text(
              '${artist.downloadCount}곡',
              style: TextStyle(color: cs.textTertiary, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

/// 트랙 타일 위젯.
class _TrackTile extends StatelessWidget {
  final Recommendation track;
  final AppColorScheme cs;
  final VoidCallback onStream;
  final VoidCallback onDownload;

  const _TrackTile({
    required this.track,
    required this.cs,
    required this.onStream,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          // 썸네일 + 재생 영역
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onStream,
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    child: CachedNetworkImage(
                      imageUrl: track.thumbnailUrl,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          track.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.tileTitle,
                        ),
                        if (track.duration != null)
                          Text(
                            _formatDuration(track.duration!),
                            style: AppTextStyles.caption
                                .copyWith(color: cs.textTertiary),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 다운로드 버튼
          IconButton(
            icon: Icon(Icons.download,
                color: cs.textSecondary, size: AppSizes.iconMd),
            onPressed: onDownload,
          ),
        ],
      ),
    );
  }

  /// [Duration]을 "M:SS" 형식으로 변환.
  String _formatDuration(Duration d) {
    final mins = d.inMinutes;
    final secs = d.inSeconds % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }
}

/// 관련 아티스트 칩 위젯.
class _RelatedArtistChip extends StatelessWidget {
  final ArtistNode artist;
  final AppColorScheme cs;
  final VoidCallback onTap;

  const _RelatedArtistChip({
    required this.artist,
    required this.cs,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: cs.surfaceVariant,
              backgroundImage: artist.thumbnailUrl != null
                  ? CachedNetworkImageProvider(artist.thumbnailUrl!)
                  : null,
              child: artist.thumbnailUrl == null
                  ? Icon(Icons.person, color: cs.textTertiary)
                  : null,
            ),
            const SizedBox(height: AppSpacing.xs),
            SizedBox(
              width: 70,
              child: Text(
                artist.name,
                style:
                    AppTextStyles.caption.copyWith(color: cs.textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
