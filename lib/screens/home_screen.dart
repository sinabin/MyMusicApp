import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/download_state.dart';
import '../providers/download_provider.dart';
import '../providers/history_provider.dart';
import '../providers/recommendation_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/video_info_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/download_button.dart';
import '../widgets/download_history_tile.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/gradient_text.dart';
import '../widgets/progress_indicator_bar.dart';
import '../widgets/settings_bottom_sheet.dart';
import '../widgets/url_input_field.dart';
import '../widgets/video_preview_card.dart';

/// 앱의 메인 화면.
///
/// URL 입력, 영상 미리보기, 다운로드 버튼, 다운로드 기록 목록을 포함.
/// [VideoInfoProvider]·[DownloadProvider]·[HistoryProvider]·[SettingsProvider]를
/// 구독하여 전체 다운로드 워크플로우를 조율.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _currentVideoId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HistoryProvider>().loadHistory();
    });
  }

  void _onUrlValid(String videoId) {
    if (_currentVideoId != videoId) {
      _currentVideoId = videoId;
      context.read<VideoInfoProvider>().fetchInfo(videoId);
    }
  }

  void _onUrlCleared() {
    _currentVideoId = null;
    context.read<VideoInfoProvider>().clear();
  }

  Future<void> _startDownload() async {
    final videoInfo = context.read<VideoInfoProvider>().videoInfo;
    if (videoInfo == null) return;

    final settings = context.read<SettingsProvider>().settings;
    final downloadProvider = context.read<DownloadProvider>();
    final historyProvider = context.read<HistoryProvider>();

    final item = await downloadProvider.startDownload(
      videoInfo: videoInfo,
      savePath: settings.savePath,
    );

    if (item != null) {
      historyProvider.addItem(item);
      if (mounted) {
        context.read<RecommendationProvider>().invalidateCache();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved: ${item.fileName}'),
            action: SnackBarAction(
              label: 'OK',
              onPressed: () {},
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
                    child: const Icon(Icons.music_note, color: Colors.white, size: 20),
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
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings_outlined, color: AppColors.textSecondary),
                  onPressed: () => SettingsBottomSheet.show(context),
                ),
              ],
            ),

            // Content
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 16),

                  // Hero heading
                  GradientText(
                    text: 'Download Audio',
                    style: AppTextStyles.heroTitle,
                    gradient: AppColors.headingGradient,
                  ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.2, end: 0),
                  const SizedBox(height: 6),
                  Text(
                    'Paste a YouTube link to download audio',
                    style: AppTextStyles.subtitle,
                  ).animate().fadeIn(duration: 600.ms, delay: 100.ms),
                  const SizedBox(height: 24),

                  // URL input
                  UrlInputField(
                    onUrlChanged: (_) {},
                    onUrlValid: _onUrlValid,
                    onUrlCleared: _onUrlCleared,
                  ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
                  const SizedBox(height: 16),

                  // Video preview
                  Consumer<VideoInfoProvider>(
                    builder: (context, provider, _) {
                      if (provider.isLoading) {
                        return const VideoPreviewShimmer();
                      }
                      if (provider.videoInfo != null) {
                        return VideoPreviewCard(videoInfo: provider.videoInfo!)
                            .animate()
                            .fadeIn(duration: 400.ms)
                            .slideY(begin: 0.1, end: 0);
                      }
                      if (provider.error != null) {
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Failed to load video info',
                                  style: TextStyle(color: AppColors.error, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  const SizedBox(height: 20),

                  // Download button + progress
                  Consumer2<DownloadProvider, VideoInfoProvider>(
                    builder: (context, downloadProv, videoProv, _) {
                      return Column(
                        children: [
                          DownloadButton(
                            status: downloadProv.status,
                            enabled: videoProv.videoInfo != null &&
                                !downloadProv.status.isActive,
                            onPressed: _startDownload,
                            onCancel: () => downloadProv.cancel(),
                            onRetry: () {
                              downloadProv.reset();
                              _startDownload();
                            },
                          ),
                          if (downloadProv.status.isActive &&
                              downloadProv.status.phase != DownloadPhase.fetching) ...[
                            const SizedBox(height: 12),
                            ProgressIndicatorBar(
                              status: downloadProv.status,
                              onCancel: () => downloadProv.cancel(),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 32),

                  // Divider
                  const Divider(color: AppColors.divider),
                  const SizedBox(height: 16),

                  // Download history header
                  Consumer<HistoryProvider>(
                    builder: (context, history, _) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recent Downloads (${history.count})',
                            style: AppTextStyles.sectionHeader,
                          ),
                          if (history.count > 0)
                            TextButton(
                              onPressed: () => history.clearHistory(),
                              child: const Text(
                                'Clear',
                                style: TextStyle(color: AppColors.textTertiary, fontSize: 13),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                ]),
              ),
            ),

            // Download history list
            Consumer<HistoryProvider>(
              builder: (context, history, _) {
                if (history.count == 0) {
                  return const SliverToBoxAdapter(child: EmptyStateWidget());
                }
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = history.items[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: DownloadHistoryTile(
                            item: item,
                            onDelete: () => history.removeItem(index),
                          ).animate().fadeIn(duration: 300.ms, delay: (index * 50).ms),
                        );
                      },
                      childCount: history.count,
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
}
