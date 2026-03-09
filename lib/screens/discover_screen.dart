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
import '../providers/premium_provider.dart';
import '../providers/recommendation_provider.dart';
import '../providers/settings_provider.dart';
import '../services/youtube_service.dart';
import '../theme/app_color_scheme.dart';
import '../theme/app_colors.dart';
import '../theme/app_durations.dart';
import '../theme/app_sizes.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_text.dart';
import '../widgets/premium_gate.dart';
import '../widgets/recommendation_card.dart';
import '../widgets/recommendation_detail_sheet.dart';

/// 음악 추천 화면.
///
/// [RecommendationProvider]를 구독하여 섹션별 추천 목록을 표시.
/// 상태별 UI: 로딩(shimmer), 에러(재시도), 빈 결과, 섹션별 결과 목록.
/// 무료 사용자는 섹션당 3건까지 표시, 나머지는 [PremiumGate]로 게이팅.
class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  /// 무료 사용자에게 섹션당 노출하는 최대 항목 수.
  static const _freeLimit = 3;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecommendationProvider>().loadSectioned();
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
        final cs = AppColorScheme.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: cs.success, size: AppSizes.iconMd),
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
    final cs = AppColorScheme.of(context);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App bar
            SliverAppBar(
              floating: true,
              backgroundColor: cs.scaffoldBackground,
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
                      icon: Icon(
                        Icons.refresh,
                        color: cs.textSecondary,
                      ),
                      onPressed: provider.isLoading
                          ? null
                          : () => provider.loadSectioned(force: true),
                    );
                  },
                ),
              ],
            ),

            // Hero section
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
                    style: AppTextStyles.subtitle.copyWith(color: cs.textSecondary),
                  ).animate().fadeIn(duration: AppDurations.emphasis, delay: 100.ms),
                  const SizedBox(height: AppSpacing.xxl),
                ]),
              ),
            ),

            // 섹션별 추천 목록
            Consumer<RecommendationProvider>(
              builder: (context, recProvider, _) {
                // 로딩
                if (recProvider.isLoading) {
                  return _buildShimmer(cs);
                }

                // 에러
                if (recProvider.error != null) {
                  return _buildError(recProvider, cs);
                }

                // 빈 결과
                final sectioned = recProvider.sectioned;
                if (sectioned == null || sectioned.isEmpty) {
                  return _buildEmpty(cs);
                }

                // 섹션별 결과 목록
                return _buildSections(recProvider, cs);
              },
            ),

            // Bottom padding
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxxl)),
          ],
        ),
      ),
    );
  }

  /// 섹션별 추천 목록 위젯 생성.
  Widget _buildSections(RecommendationProvider recProvider, AppColorScheme cs) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      sliver: Selector2<DownloadProvider, PremiumProvider, (bool, String?, bool)>(
        selector: (_, dp, pp) => (dp.status.isActive, dp.currentVideoId, pp.isPremium),
        builder: (context, data, _) {
          final (isActive, currentVideoId, isPremium) = data;
          final children = <Widget>[];

          // For You 섹션
          if (recProvider.forYouItems.isNotEmpty) {
            children.add(_buildSectionHeader(
              cs,
              icon: Icons.auto_awesome,
              title: 'For You',
              count: recProvider.forYouItems.length,
            ));
            children.add(_buildSectionItems(
              recProvider.forYouItems,
              isPremium,
              isActive,
              currentVideoId,
              recProvider,
            ));
          }

          // Trending 섹션
          if (recProvider.trendingItems.isNotEmpty) {
            if (children.isNotEmpty) {
              children.add(Divider(color: cs.divider, height: AppSpacing.xxxl));
            }
            children.add(_buildSectionHeader(
              cs,
              icon: Icons.trending_up,
              title: 'Trending',
              count: recProvider.trendingItems.length,
            ));
            children.add(_buildSectionItems(
              recProvider.trendingItems,
              isPremium,
              isActive,
              currentVideoId,
              recProvider,
            ));
          }

          // Similar Songs 섹션
          if (recProvider.similarItems.isNotEmpty) {
            if (children.isNotEmpty) {
              children.add(Divider(color: cs.divider, height: AppSpacing.xxxl));
            }
            children.add(_buildSectionHeader(
              cs,
              icon: Icons.queue_music,
              title: 'Similar Songs',
              count: recProvider.similarItems.length,
            ));
            children.add(_buildSectionItems(
              recProvider.similarItems,
              isPremium,
              isActive,
              currentVideoId,
              recProvider,
            ));
          }

          return SliverList(
            delegate: SliverChildListDelegate(children),
          );
        },
      ),
    );
  }

  /// 섹션 헤더 위젯.
  Widget _buildSectionHeader(
    AppColorScheme cs, {
    required IconData icon,
    required String title,
    required int count,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Icon(icon, color: cs.primary, size: AppSizes.iconMd),
          const SizedBox(width: AppSpacing.sm),
          Text(title, style: AppTextStyles.sectionHeader),
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xxs,
            ),
            decoration: BoxDecoration(
              color: cs.primarySurface,
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Text(
              '$count',
              style: AppTextStyles.caption.copyWith(
                color: cs.primaryLight,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 섹션별 아이템 목록 위젯 (프리미엄 게이팅 포함).
  Widget _buildSectionItems(
    List<Recommendation> items,
    bool isPremium,
    bool isDownloadActive,
    String? currentVideoId,
    RecommendationProvider recProvider,
  ) {
    final visibleItems = isPremium ? items : items.take(_freeLimit).toList();
    final hasMore = !isPremium && items.length > _freeLimit;

    return Column(
      children: [
        for (int i = 0; i < visibleItems.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _buildCard(
              visibleItems[i],
              isDownloadActive,
              currentVideoId,
              recProvider,
            ).animate().fadeIn(
                  duration: AppDurations.normal,
                  delay: Duration(
                    milliseconds: (i * AppDurations.staggerMs)
                        .clamp(0, AppDurations.staggerMaxLongMs),
                  ),
                ),
          ),
        if (hasMore)
          PremiumGate(
            featureLabel: '더 많은 추천 보기',
            child: Column(
              children: [
                for (final rec in items.skip(_freeLimit).take(3))
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _buildCard(
                      rec,
                      isDownloadActive,
                      currentVideoId,
                      recProvider,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  /// 개별 추천 카드 위젯 생성.
  Widget _buildCard(
    Recommendation rec,
    bool isDownloadActive,
    String? currentVideoId,
    RecommendationProvider recProvider,
  ) {
    final isThis = isDownloadActive && currentVideoId == rec.videoId;
    return RecommendationCard(
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
    );
  }

  /// 로딩 shimmer 위젯.
  Widget _buildShimmer(AppColorScheme cs) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Shimmer.fromColors(
                baseColor: cs.surface,
                highlightColor: cs.surfaceVariant,
                child: Container(
                  height: AppSizes.thumbnailXl,
                  decoration: BoxDecoration(
                    color: cs.surface,
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
  Widget _buildError(RecommendationProvider provider, AppColorScheme cs) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      sliver: SliverToBoxAdapter(
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: cs.border),
          ),
          child: Column(
            children: [
              Icon(
                Icons.cloud_off,
                color: cs.textTertiary,
                size: AppSizes.iconHero,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                provider.error!,
                style: AppTextStyles.body.copyWith(color: cs.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              TextButton.icon(
                onPressed: () => provider.loadSectioned(force: true),
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
  Widget _buildEmpty(AppColorScheme cs) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      sliver: SliverToBoxAdapter(
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: cs.border),
          ),
          child: Column(
            children: [
              Icon(
                Icons.music_note_outlined,
                color: cs.textTertiary,
                size: AppSizes.iconHero,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                '새로운 추천을 준비 중입니다',
                style: AppTextStyles.body.copyWith(color: cs.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '더 많은 곡을 다운로드하면 정확한 추천이 가능해요',
                style: AppTextStyles.caption.copyWith(color: cs.textTertiary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
