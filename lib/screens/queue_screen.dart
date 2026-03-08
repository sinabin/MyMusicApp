import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/player_provider.dart';
import '../theme/app_colors.dart';
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 드래그 핸들
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textTertiary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // 헤더
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Consumer<PlayerProvider>(
                  builder: (context, player, _) => Text(
                    'Queue (${player.queue.length})',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
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
                        32, 32, 32, 32 + bottomPadding),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.queue_music,
                          size: 48,
                          color: AppColors.textTertiary,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Queue is empty',
                          style: TextStyle(
                            color: AppColors.textTertiary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Play a song to start your queue',
                          style: TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return ReorderableListView.builder(
                  padding: EdgeInsets.fromLTRB(
                      0, 8, 0, 8 + bottomPadding),
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
                        padding: const EdgeInsets.only(right: 20),
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
