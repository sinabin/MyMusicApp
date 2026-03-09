import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../models/download_item.dart';
import '../models/recommendation.dart';
import '../models/video_info.dart';
import '../providers/download_provider.dart';
import '../providers/history_provider.dart';
import '../providers/player_provider.dart';
import '../providers/recommendation_provider.dart';
import '../providers/settings_provider.dart';
import '../services/youtube_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_durations.dart';
import '../theme/app_sizes.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_text.dart';
import '../widgets/recommendation_card.dart';
import '../widgets/recommendation_detail_sheet.dart';

/// 음악 추천 화면.
///
/// [RecommendationProvider]를 구독하여 추천 목록을 표시.
/// 상태별 UI: 로딩(shimmer), 에러(재시도), cold start(안내), 빈 결과, 결과 목록.
class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecommendationProvider>().loadRecommendations();
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
    final recProvider = context.read<RecommendationProvider>();

    final item = await downloadProvider.startDownload(
      videoInfo: videoInfo,
      savePath: settings.savePath,
    );

    if (item != null) {
      historyProvider.addItem(item);
      recProvider.removeFromCurrent(rec.videoId);
      recProvider.markCacheStale();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: AppColors.success, size: AppSizes.iconMd),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App bar
            SliverAppBar(
              floating: true,
              backgroundColor: AppColors.scaffoldBackground,
              title: Row(
                children: [
                  Container(
                    width: AppSizes.headerIconBox,
                    height: AppSizes.headerIconBox,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: const Icon(Icons.explore, color: Colors.white, size: AppSizes.iconMd),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Discover',
                    style: AppTextStyles.sectionHeader,
                  ),
                ],
              ),
              actions: [
                Consumer<RecommendationProvider>(
                  builder: (context, provider, _) {
                    return IconButton(
                      icon: const Icon(
                        Icons.refresh,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: provider.isLoading
                          ? null
                          : () => provider.loadRecommendations(force: true),
                    );
                  },
                ),
              ],
            ),

            // Content
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: AppSpacing.lg),
                  GradientText(
                    text: 'For You',
                    style: AppTextStyles.heroTitle,
                    gradient: AppColors.headingGradient,
                  ).animate().fadeIn(duration: AppDurations.emphasis).slideY(begin: -0.2, end: 0),
                  const SizedBox(height: 6),
                  Text(
                    'Recommendations based on your downloads',
                    style: AppTextStyles.subtitle,
                  ).animate().fadeIn(duration: AppDurations.emphasis, delay: 100.ms),
                  const SizedBox(height: AppSpacing.xxl),
                ]),
              ),
            ),

            // 추천 목록
            Consumer<RecommendationProvider>(
              builder: (context, recProvider, _) {
                // 로딩
                if (recProvider.isLoading) {
                  return _buildShimmer();
                }

                // 에러
                if (recProvider.error != null) {
                  return _buildError(recProvider);
                }

                // 빈 결과
                if (recProvider.items.isEmpty) {
                  return _buildEmpty();
                }

                // 결과 목록
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                  sliver: Selector<DownloadProvider, (bool, String?)>(
                    selector: (_, dp) => (dp.status.isActive, dp.currentVideoId),
                    builder: (context, dlData, _) {
                      final (isActive, currentVideoId) = dlData;
                      return SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final rec = recProvider.items[index];
                            final isThis = isActive &&
                                currentVideoId == rec.videoId;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                              child: RecommendationCard(
                                recommendation: rec,
                                isDownloading: isThis,
                                onDownload: () => _onDownload(rec),
                                onDismiss: () => recProvider.dismiss(rec.videoId),
                                onTap: () => RecommendationDetailSheet.show(
                                  context,
                                  recommendation: rec,
                                  onDownload: () => _onDownload(rec),
                                  onStream: () => _onStream(rec),
                                  isDownloading: isThis,
                                ),
                              ).animate().fadeIn(
                                duration: AppDurations.normal,
                                delay: Duration(milliseconds: (index * AppDurations.staggerMs).clamp(0, AppDurations.staggerMaxLongMs)),
                              ),
                            );
                          },
                          childCount: recProvider.items.length,
                        ),
                      );
                    },
                  ),
                );
              },
            ),

            // Bottom padding
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxxl)),
          ],
        ),
      ),
    );
  }

  /// 로딩 shimmer 위젯.
  Widget _buildShimmer() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Shimmer.fromColors(
                baseColor: AppColors.surface,
                highlightColor: AppColors.surfaceVariant,
                child: Container(
                  height: AppSizes.thumbnailXl,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                ),
              ),
            );
          },
          childCount: 6,
        ),
      ),
    );
  }

  /// 에러 상태 위젯.
  Widget _buildError(RecommendationProvider provider) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      sliver: SliverToBoxAdapter(
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.cloud_off,
                color: AppColors.textTertiary,
                size: AppSizes.iconHero,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                provider.error!,
                style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              TextButton.icon(
                onPressed: () => provider.loadRecommendations(force: true),
                icon: const Icon(Icons.refresh, size: AppSizes.iconMsl),
                label: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 빈 결과 상태 위젯.
  Widget _buildEmpty() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      sliver: SliverToBoxAdapter(
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.music_note_outlined,
                color: AppColors.textTertiary,
                size: AppSizes.iconHero,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                '새로운 추천을 준비 중입니다',
                style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '더 많은 곡을 다운로드하면 정확한 추천이 가능해요',
                style: AppTextStyles.caption,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
