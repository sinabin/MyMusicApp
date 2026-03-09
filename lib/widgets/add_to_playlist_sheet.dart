import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/playlist_provider.dart';
import '../theme/app_color_scheme.dart';
import '../theme/app_sizes.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import '../utils/format_utils.dart';
import 'playlist_mosaic_art.dart';

/// 곡을 플레이리스트에 추가하는 바텀시트.
///
/// 기존 플레이리스트 선택 또는 인라인으로 새 플레이리스트 생성 후 곡 추가.
/// [AddToPlaylistSheet.show]로 표시.
class AddToPlaylistSheet extends StatefulWidget {
  /// 추가할 곡의 videoId.
  final String videoId;

  const AddToPlaylistSheet({super.key, required this.videoId});

  /// 바텀시트를 모달로 표시.
  static void show(BuildContext context, {required String videoId}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddToPlaylistSheet(videoId: videoId),
    );
  }

  @override
  State<AddToPlaylistSheet> createState() => _AddToPlaylistSheetState();
}

class _AddToPlaylistSheetState extends State<AddToPlaylistSheet> {
  final _newNameController = TextEditingController();

  @override
  void dispose() {
    _newNameController.dispose();
    super.dispose();
  }

  Future<void> _createAndAdd() async {
    final name = _newNameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a playlist name')),
      );
      return;
    }
    try {
      final provider = context.read<PlaylistProvider>();
      final playlist = await provider.createPlaylist(name);
      await provider.addTrackToPlaylist(playlist, widget.videoId);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Added to $name')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = AppColorScheme.of(context);
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
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
                Text(
                  'Add to Playlist',
                  style: AppTextStyles.sectionHeader,
                ),
                IconButton(
                  icon: Icon(Icons.close, color: cs.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          // 인라인 새 플레이리스트 생성
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newNameController,
                    style: AppTextStyles.body,
                    decoration: InputDecoration(
                      hintText: 'New playlist name',
                      hintStyle: TextStyle(
                        color: cs.textTertiary,
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: cs.surfaceVariant,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: 10,
                      ),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                IconButton(
                  icon: Icon(
                    Icons.add_circle,
                    color: cs.primary,
                  ),
                  onPressed: _createAndAdd,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl, vertical: AppSpacing.sm),
            child: Divider(color: cs.divider, height: 1),
          ),
          // 기존 플레이리스트 목록
          Flexible(
            child: Consumer<PlaylistProvider>(
              builder: (context, provider, _) {
                if (provider.playlists.isEmpty) {
                  return Padding(
                    padding: EdgeInsets.fromLTRB(
                        AppSpacing.xxxl, AppSpacing.xxxl, AppSpacing.xxxl, AppSpacing.xxxl + bottomPadding),
                    child: Text(
                      'No playlists yet',
                      style: TextStyle(color: cs.textTertiary),
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.fromLTRB(
                      AppSpacing.xxl, AppSpacing.sm, AppSpacing.xxl, AppSpacing.sm + bottomPadding),
                  itemCount: provider.playlists.length,
                  itemBuilder: (context, index) {
                    final playlist = provider.playlists[index];
                    final tracks =
                        provider.getTracksForPlaylist(playlist);
                    final urls = tracks
                        .take(4)
                        .map((t) => t.thumbnailUrl)
                        .toList();
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: PlaylistMosaicArt(
                        thumbnailUrls: urls,
                        size: AppSizes.thumbnailSm,
                      ),
                      title: Text(
                        playlist.name,
                        style: AppTextStyles.body,
                      ),
                      subtitle: Text(
                        FormatUtils.trackCount(
                          playlist.trackVideoIds.length,
                        ),
                        style: AppTextStyles.caption.copyWith(color: cs.textTertiary),
                      ),
                      onTap: () async {
                        HapticFeedback.lightImpact();
                        try {
                          await provider.addTrackToPlaylist(
                            playlist,
                            widget.videoId,
                          );
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Added to ${playlist.name}'),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    ),
    );
  }
}
