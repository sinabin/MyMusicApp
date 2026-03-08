import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../models/video_info.dart';
import '../providers/download_provider.dart';
import '../providers/history_provider.dart';
import '../providers/recommendation_provider.dart';
import '../providers/search_provider.dart';
import '../providers/settings_provider.dart';
import '../services/youtube_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
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

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 상단 여백 + 검색바
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
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
                    size: 20,
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
            size: 64,
            color: AppColors.textTertiary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
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
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text('Search failed', style: AppTextStyles.sectionHeader),
            const SizedBox(height: 8),
            Text(
              error,
              style: AppTextStyles.caption,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
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
            size: 48,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 12),
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
          padding: const EdgeInsets.symmetric(horizontal: 16),
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
              isDownloading: isThisDownloading,
              downloadDisabled: isActive && !isThisDownloading,
            ).animate().fadeIn(
                  duration: 200.ms,
                  delay: Duration(milliseconds: (index * 30).clamp(0, 300)),
                );
          },
        );
      },
    );
  }
}

/// 다운로드 확인 바텀 시트.
///
/// 검색 결과의 미리보기 정보와 다운로드 버튼을 표시.
class _DownloadConfirmSheet extends StatelessWidget {
  final VideoInfo videoInfo;
  final VoidCallback onDownload;

  const _DownloadConfirmSheet({
    required this.videoInfo,
    required this.onDownload,
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
                child: Image.network(
                  videoInfo.thumbnailUrl,
                  width: 120,
                  height: 68,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 120,
                    height: 68,
                    color: AppColors.surfaceVariant,
                    child: const Icon(
                      Icons.music_note,
                      color: AppColors.textTertiary,
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
                        gradient:
                            isActive ? null : AppColors.primaryGradient,
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
                                  : Colors.white,
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
                                    : Colors.white,
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
