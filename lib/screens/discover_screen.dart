import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../models/recommendation.dart';
import '../models/video_info.dart';
import '../providers/download_provider.dart';
import '../providers/history_provider.dart';
import '../providers/recommendation_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
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
                const Icon(Icons.check_circle, color: AppColors.success, size: 20),
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
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.explore, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Discover',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
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
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 16),
                  GradientText(
                    text: 'For You',
                    style: AppTextStyles.heroTitle,
                    gradient: AppColors.headingGradient,
                  ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.2, end: 0),
                  const SizedBox(height: 6),
                  Text(
                    'Recommendations based on your downloads',
                    style: AppTextStyles.subtitle,
                  ).animate().fadeIn(duration: 600.ms, delay: 100.ms),
                  const SizedBox(height: 24),
                ]),
              ),
            ),

            // 추천 목록
            Consumer2<RecommendationProvider, DownloadProvider>(
              builder: (context, recProvider, dlProvider, _) {
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
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final rec = recProvider.items[index];
                        final isThis = dlProvider.status.isActive &&
                            dlProvider.currentVideoId == rec.videoId;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: RecommendationCard(
                            recommendation: rec,
                            isDownloading: isThis,
                            onDownload: () => _onDownload(rec),
                            onDismiss: () => recProvider.dismiss(rec.videoId),
                            onTap: () => RecommendationDetailSheet.show(
                              context,
                              recommendation: rec,
                              onDownload: () => _onDownload(rec),
                              isDownloading: isThis,
                            ),
                          ).animate().fadeIn(
                            duration: 300.ms,
                            delay: (index * 50).clamp(0, 500).ms,
                          ),
                        );
                      },
                      childCount: recProvider.items.length,
                    ),
                  ),
                );
              },
            ),

            // Bottom padding
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  /// 로딩 shimmer 위젯.
  Widget _buildShimmer() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Shimmer.fromColors(
                baseColor: AppColors.surface,
                highlightColor: AppColors.surfaceVariant,
                child: Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
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
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverToBoxAdapter(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.cloud_off,
                color: AppColors.textTertiary,
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                provider.error!,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () => provider.loadRecommendations(force: true),
                icon: const Icon(Icons.refresh, size: 18),
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
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverToBoxAdapter(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: const Column(
            children: [
              Icon(
                Icons.music_note_outlined,
                color: AppColors.textTertiary,
                size: 48,
              ),
              SizedBox(height: 12),
              Text(
                '새로운 추천을 준비 중입니다',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 4),
              Text(
                '더 많은 곡을 다운로드하면 정확한 추천이 가능해요',
                style: TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
