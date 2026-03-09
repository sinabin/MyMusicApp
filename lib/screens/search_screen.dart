import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../models/app_exception.dart';
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
import '../theme/app_durations.dart';
import '../theme/app_sizes.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import '../widgets/download_confirm_sheet.dart';
import '../widgets/search_result_tile.dart';

/// YouTube 검색 화면.
///
/// 검색어 입력·결과 표시·다운로드 트리거를 담당.
/// [SearchProvider]를 구독하여 검색 상태를 관리하고,
/// [DownloadProvider]를 통해 검색 결과에서 바로 다운로드 수행.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();

  /// 스트리밍 준비 중인 영상 ID.
  String? _streamingVideoId;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<SearchProvider>().loadMore();
    }
  }

  void _onSearch() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      _focusNode.unfocus();
      context.read<SearchProvider>().search(query);
    }
  }

  void _onClear() {
    _searchController.clear();
    context.read<SearchProvider>().clear();
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
      // 전체 메타데이터 조회 (Home 화면의 VideoInfoProvider를 건드리지 않음)
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
        final msg = e is AppException ? e.userMessage : 'Download failed';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
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
        final msg = e is AppException ? e.userMessage : 'Streaming failed';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    } finally {
      if (mounted) setState(() => _streamingVideoId = null);
    }
  }

  void _showDownloadSheet(VideoInfo info) {
    DownloadConfirmSheet.show(
      context,
      videoInfo: info,
      onDownload: () {
        Navigator.of(context).pop();
        _onDownloadTap(info);
      },
      onStream: () {
        Navigator.of(context).pop();
        _onStreamTap(info);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.read<SearchProvider>().clear();
            Navigator.pop(context);
          },
        ),
        title: const Text('검색'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 검색바
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
              child: _buildSearchBar(),
            ),
            // 결과 영역
            Expanded(
              child: Consumer<SearchProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading) {
                    return _buildLoadingState();
                  }
                  if (provider.error != null) {
                    return _buildErrorState(provider.error!);
                  }
                  if (provider.results.isEmpty && provider.query.isNotEmpty) {
                    return _buildEmptyState();
                  }
                  if (provider.results.isEmpty) {
                    return _buildInitialState();
                  }
                  return _buildResultsList(provider);
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
      height: AppSizes.searchBarHeight,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          const Icon(Icons.search, color: AppColors.textTertiary, size: AppSizes.iconMl),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _focusNode,
              style: AppTextStyles.inputText,
              decoration: const InputDecoration(
                hintText: 'Search YouTube...',
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
                    size: AppSizes.iconMd,
                  ),
                  onPressed: _onClear,
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInitialState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search,
            size: AppSizes.iconJumbo,
            color: AppColors.textTertiary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Search for music to download',
            style: AppTextStyles.subtitle,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.primary),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: AppSizes.iconHero, color: AppColors.error),
            const SizedBox(height: AppSpacing.md),
            Text('Search failed', style: AppTextStyles.sectionHeader),
            const SizedBox(height: AppSpacing.sm),
            Text(
              error,
              style: AppTextStyles.caption,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.lg),
            TextButton(
              onPressed: _onSearch,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.search_off,
            size: AppSizes.iconHero,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text('No results found', style: AppTextStyles.subtitle),
        ],
      ),
    );
  }

  Widget _buildResultsList(SearchProvider provider) {
    return Consumer<DownloadProvider>(
      builder: (context, downloadProv, _) {
        final isActive = downloadProv.status.isActive;
        final currentVideoId = downloadProv.currentVideoId;

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          itemCount:
              provider.results.length + (provider.isLoadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == provider.results.length) {
              return const Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: AppSizes.strokeWidth,
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
                  duration: AppDurations.fast,
                  delay: Duration(milliseconds: (index * AppDurations.staggerFastMs).clamp(0, AppDurations.staggerMaxMs)),
                );
          },
        );
      },
    );
  }
}
