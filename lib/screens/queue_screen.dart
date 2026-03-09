import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/player_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_durations.dart';
import '../theme/app_sizes.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import '../widgets/track_list_tile.dart';

/// 현재 재생 큐를 표시하는 바텀시트.
///
/// [ReorderableListView]로 순서 변경, 스와이프로 제거 지원.
/// 현재 재생 곡을 하이라이트 표시.
class QueueScreen extends StatelessWidget {
  const QueueScreen({super.key});

  /// 큐 바텀시트를 모달로 표시.
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const QueueScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXl)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 드래그 핸들
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.sm),
            child: Container(
              width: AppSizes.handleWidth,
              height: AppSizes.handleHeight,
              decoration: BoxDecoration(
                color: AppColors.textTertiary,
                borderRadius: BorderRadius.circular(AppSpacing.xxs),
              ),
            ),
          ),
          // 헤더
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl, vertical: AppSpacing.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Selector<PlayerProvider, int>(
                  selector: (_, p) => p.queue.length,
                  builder: (context, count, _) => Text(
                    L.of(context)!.queueCount(count),
                    style: AppTextStyles.sectionHeader,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.divider, height: 1),
          // 큐 목록
          Flexible(
            child: Consumer<PlayerProvider>(
              builder: (context, player, _) {
                if (player.queue.isEmpty) {
                  return Padding(
                    padding: EdgeInsets.fromLTRB(
                        AppSpacing.xxxl, AppSpacing.xxxl, AppSpacing.xxxl,
                        AppSpacing.xxxl + bottomPadding),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.queue_music,
                          size: AppSizes.iconHero,
                          color: AppColors.textTertiary,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          L.of(context)!.queueEmpty,
                          style: const TextStyle(
                            color: AppColors.textTertiary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          L.of(context)!.queueEmptyHint,
                          style: const TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ).animate().fadeIn(duration: AppDurations.normal),
                  );
                }
                return ReorderableListView.builder(
                  padding: EdgeInsets.fromLTRB(
                      0, AppSpacing.sm, 0, AppSpacing.sm + bottomPadding),
                  itemCount: player.queue.length,
                  onReorder: (oldIndex, newIndex) {
                    if (newIndex > oldIndex) newIndex--;
                    player.moveInQueue(oldIndex, newIndex);
                  },
                  itemBuilder: (context, index) {
                    final item = player.queue[index];
                    final isCurrent = index == player.currentIndex;
                    return Dismissible(
                      key: ValueKey('${item.videoId}_$index'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: AppSpacing.xl),
                        color: AppColors.error.withValues(alpha: 0.2),
                        child: const Icon(
                          Icons.delete,
                          color: AppColors.error,
                        ),
                      ),
                      onDismissed: (_) => player.removeFromQueue(index),
                      child: TrackListTile(
                        item: item,
                        isCurrentTrack: isCurrent,
                        onTap: () {
                          if (!isCurrent) {
                            player.skipToIndex(index);
                          }
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
