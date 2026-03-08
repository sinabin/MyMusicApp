import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import '../models/download_item.dart';
import '../models/video_info.dart';
import '../providers/download_provider.dart';
import '../providers/history_provider.dart';
import '../providers/player_provider.dart';
import '../providers/recommendation_provider.dart';
import '../providers/search_provider.dart';
import '../providers/settings_provider.dart';
import '../services/youtube_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/add_to_playlist_sheet.dart';
import '../widgets/download_history_tile.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/search_result_tile.dart';
import '../widgets/settings_bottom_sheet.dart';

/// 앱의 메인 화면.
///
/// 검색바·검색 결과·다운로드 기록을 통합 표시.
/// 검색 미입력 시 최근 다운로드 목록, 검색 시 YouTube 결과를 표시.
/// [SearchProvider]·[DownloadProvider]·[HistoryProvider]를
/// 구독하여 검색·다운로드·재생 워크플로우를 조율.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  final _searchScrollController = ScrollController();
  final _historyScrollController = ScrollController();

  /// 스트리밍 준비 중인 영상 ID.
  String? _streamingVideoId;

  @override
  void initState() {
    super.initState();
    _searchScrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HistoryProvider>().loadHistory();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _searchScrollController.dispose();
    _historyScrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final searchProvider = context.read<SearchProvider>();
    if (searchProvider.results.isNotEmpty &&
        _searchScrollController.position.pixels >=
            _searchScrollController.position.maxScrollExtent - 200) {
      searchProvider.loadMore();
    }
  }

  void _onSearch() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      _focusNode.unfocus();
      context.read<SearchProvider>().search(query);
    }
  }

  void _onClearSearch() {
    _searchController.clear();
    context.read<SearchProvider>().clear();
  }

  void _playFromHistory(List<DownloadItem> items, int index) {
    final player = context.read<PlayerProvider>();
    final playAll = context.read<SettingsProvider>().settings.playAllOnTap;
    if (playAll) {
      player.playAll(items, startIndex: index);
    } else {
      player.playTrack(items[index]);
    }
  }

  Future<void> _onStreamTap(VideoInfo info) async {
    if (_streamingVideoId != null) return;
    setState(() => _streamingVideoId = info.videoId);

    try {
      final youtubeService = context.read<YouTubeService>();
      final streamUrl = await youtubeService.getAudioStreamUrl(info.videoId);

      if (!mounted) return;

      final streamItem = DownloadItem.streaming(
        videoId: info.videoId,
        title: info.title,
        streamUrl: streamUrl.toString(),
        thumbnailUrl: info.thumbnailUrl,
        channelName: info.channelName,
        channelId: info.channelId,
        artistName: info.artistName,
        keywords: info.keywords,
        durationInMs: info.duration.inMilliseconds,
      );

      context.read<PlayerProvider>().playTrack(streamItem);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Streaming failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _streamingVideoId = null);
    }
  }

  void _onResultTap(VideoInfo info) {
    _showDownloadSheet(info);
  }

  Future<void> _onDownloadTap(VideoInfo info) async {
    final downloadProvider = context.read<DownloadProvider>();
    if (downloadProvider.status.isActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A download is already in progress')),
      );
      return;
    }
    await _performDownload(info);
  }

  Future<void> _performDownload(VideoInfo searchResult) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Preparing download...'),
        duration: Duration(seconds: 1),
      ),
    );

    try {
      final youtubeService = context.read<YouTubeService>();
      final videoInfo =
          await youtubeService.fetchVideoInfo(searchResult.videoId);

      if (!mounted) return;

      final settings = context.read<SettingsProvider>().settings;
      final downloadProvider = context.read<DownloadProvider>();
      final historyProvider = context.read<HistoryProvider>();

      final item = await downloadProvider.startDownload(
        videoInfo: videoInfo,
        savePath: settings.savePath,
      );

      if (item != null && mounted) {
        historyProvider.addItem(item);
        context.read<RecommendationProvider>().invalidateCache();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved: ${item.fileName}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: $e')),
        );
      }
    }
  }

  void _showDownloadSheet(VideoInfo info) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _DownloadConfirmSheet(
        videoInfo: info,
        onDownload: () {
          Navigator.of(context).pop();
          _onDownloadTap(info);
        },
        onStream: () {
          Navigator.of(context).pop();
          _onStreamTap(info);
        },
      ),
    );
  }

  /// 검색이 활성 상태인지 판별.
  bool _isSearchActive(SearchProvider provider) {
    return provider.query.isNotEmpty ||
        provider.results.isNotEmpty ||
        provider.isLoading;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // App bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.music_note,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'MyMusicApp',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined,
                        color: AppColors.textSecondary),
                    onPressed: () => SettingsBottomSheet.show(context),
                  ),
                ],
              ),
            ),

            // 검색바
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: _buildSearchBar(),
            ),

            // 메인 콘텐츠: 검색 결과 또는 최근 다운로드
            Expanded(
              child: Consumer<SearchProvider>(
                builder: (context, searchProvider, _) {
                  if (_isSearchActive(searchProvider)) {
                    return _buildSearchContent(searchProvider);
                  }
                  return _buildRecentDownloads();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          const Icon(Icons.search, color: AppColors.textTertiary, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _focusNode,
              style: AppTextStyles.inputText,
              decoration: const InputDecoration(
                hintText: 'Search music...',
                hintStyle: TextStyle(color: AppColors.textTertiary),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _onSearch(),
            ),
          ),
          ListenableBuilder(
            listenable: _searchController,
            builder: (context, _) {
              if (_searchController.text.isNotEmpty) {
                return IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: AppColors.textTertiary,
                    size: 20,
                  ),
                  onPressed: _onClearSearch,
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  /// 검색 활성 시: 로딩·에러·빈 결과·결과 목록.
  Widget _buildSearchContent(SearchProvider provider) {
    if (provider.isLoading && provider.results.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (provider.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text('Search failed', style: AppTextStyles.sectionHeader),
              const SizedBox(height: 8),
              Text(
                provider.error!,
                style: AppTextStyles.caption,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              TextButton(onPressed: _onSearch, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    if (provider.results.isEmpty && provider.query.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off,
                size: 48, color: AppColors.textTertiary),
            const SizedBox(height: 12),
            Text('No results found', style: AppTextStyles.subtitle),
          ],
        ),
      );
    }
    return _buildSearchResultsList(provider);
  }

  Widget _buildSearchResultsList(SearchProvider provider) {
    return Consumer<DownloadProvider>(
      builder: (context, downloadProv, _) {
        final isActive = downloadProv.status.isActive;
        final currentVideoId = downloadProv.currentVideoId;

        return ListView.builder(
          controller: _searchScrollController,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          itemCount:
              provider.results.length + (provider.isLoadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == provider.results.length) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 2,
                  ),
                ),
              );
            }
            final result = provider.results[index];
            final isThisDownloading =
                isActive && currentVideoId == result.videoId;

            return SearchResultTile(
              videoInfo: result,
              onTap: () => _onResultTap(result),
              onDownload: () => _onDownloadTap(result),
              onStream: () => _onStreamTap(result),
              isDownloading: isThisDownloading,
              isStreamLoading: _streamingVideoId == result.videoId,
              downloadDisabled: isActive && !isThisDownloading,
            ).animate().fadeIn(
                  duration: 200.ms,
                  delay: Duration(
                      milliseconds: (index * 30).clamp(0, 300)),
                );
          },
        );
      },
    );
  }

  /// 검색 미입력 시: 최근 다운로드 목록.
  Widget _buildRecentDownloads() {
    return Consumer<HistoryProvider>(
      builder: (context, history, _) {
        final recent = history.recentItems;

        return CustomScrollView(
          controller: _historyScrollController,
          slivers: [
            // 섹션 헤더
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      'Recent Downloads (${history.recentCount})',
                      style: AppTextStyles.sectionHeader,
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),

            // 목록
            if (recent.isEmpty)
              const SliverToBoxAdapter(child: EmptyStateWidget()),
            if (recent.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = recent[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: DownloadHistoryTile(
                          item: item,
                          onDelete: () => history.removeItem(index),
                          onTap: () => _playFromHistory(recent, index),
                          onAddToQueue: () {
                            context
                                .read<PlayerProvider>()
                                .addToQueue(item);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Added to queue'),
                              ),
                            );
                          },
                          isFavorite: item.isFavorite,
                          onToggleFavorite: () => context
                              .read<HistoryProvider>()
                              .toggleFavorite(item),
                          onAddToPlaylist: () => AddToPlaylistSheet.show(
                              context,
                              videoId: item.videoId),
                        ).animate().fadeIn(
                            duration: 300.ms, delay: (index * 50).ms),
                      );
                    },
                    childCount: recent.length,
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        );
      },
    );
  }
}

/// 다운로드·스트리밍 확인 바텀 시트.
///
/// 검색 결과의 미리보기 정보와 다운로드·스트리밍 버튼을 표시.
class _DownloadConfirmSheet extends StatelessWidget {
  final VideoInfo videoInfo;
  final VoidCallback onDownload;
  final VoidCallback onStream;

  const _DownloadConfirmSheet({
    required this.videoInfo,
    required this.onDownload,
    required this.onStream,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        20 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 핸들 바
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textTertiary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // 영상 정보
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 120,
                  height: 68,
                  child: CachedNetworkImage(
                    imageUrl: videoInfo.thumbnailUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Shimmer.fromColors(
                      baseColor: AppColors.surfaceVariant,
                      highlightColor: AppColors.surfaceLight,
                      child: Container(color: AppColors.surfaceVariant),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: AppColors.surfaceVariant,
                      child: const Icon(
                        Icons.music_note,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      videoInfo.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      videoInfo.channelName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    if (videoInfo.duration != Duration.zero) ...[
                      const SizedBox(height: 4),
                      Text(
                        videoInfo.formattedDuration,
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
          const SizedBox(height: 24),

          // 스트리밍 재생 버튼
          SizedBox(
            width: double.infinity,
            height: 52,
            child: Material(
              borderRadius: BorderRadius.circular(26),
              child: InkWell(
                borderRadius: BorderRadius.circular(26),
                onTap: () {
                  HapticFeedback.mediumImpact();
                  onStream();
                },
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: const Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.play_circle_outline,
                          color: Colors.white,
                          size: 22,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Stream',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // 다운로드 버튼
          Consumer<DownloadProvider>(
            builder: (context, provider, _) {
              final isActive = provider.status.isActive;
              return SizedBox(
                width: double.infinity,
                height: 52,
                child: Material(
                  borderRadius: BorderRadius.circular(26),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(26),
                    onTap: isActive
                        ? null
                        : () {
                            HapticFeedback.mediumImpact();
                            onDownload();
                          },
                    child: Ink(
                      decoration: BoxDecoration(
                        border: isActive
                            ? null
                            : Border.all(
                                color: AppColors.primary, width: 1.5),
                        color: isActive ? AppColors.surfaceVariant : null,
                        borderRadius: BorderRadius.circular(26),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.download_rounded,
                              color: isActive
                                  ? AppColors.textTertiary
                                  : AppColors.primary,
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isActive
                                  ? 'Download in progress...'
                                  : 'Download Audio',
                              style: TextStyle(
                                color: isActive
                                    ? AppColors.textTertiary
                                    : AppColors.primary,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
