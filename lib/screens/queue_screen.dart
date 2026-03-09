import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/player_provider.dart';
import '../services/file_service.dart';
import '../theme/app_color_scheme.dart';
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
    final cs = AppColorScheme.of(context);
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXl)),
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
                color: cs.textTertiary,
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
                  icon: Icon(Icons.close, color: cs.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Divider(color: cs.divider, height: 1),
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
                        Icon(
                          Icons.queue_music,
                          size: AppSizes.iconHero,
                          color: cs.textTertiary,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          L.of(context)!.queueEmpty,
                          style: TextStyle(
                            color: cs.textTertiary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          L.of(context)!.queueEmptyHint,
                          style: TextStyle(
                            color: cs.textTertiary,
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
                        color: cs.error.withValues(alpha: 0.2),
                        child: Icon(
                          Icons.delete,
                          color: cs.error,
                        ),
                      ),
                      onDismissed: (_) => player.removeFromQueue(index),
                      child: TrackListTile(
                        item: item,
                        fileService: context.read<FileService>(),
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
