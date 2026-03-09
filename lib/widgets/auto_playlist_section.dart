import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/auto_playlist.dart';
import '../providers/auto_playlist_provider.dart';
import '../providers/player_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_color_scheme.dart';
import '../theme/app_sizes.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';

/// 자동 플레이리스트를 수평 스크롤로 표시하는 섹션 위젯.
///
/// [AutoPlaylistProvider]를 구독하여 카테고리 카드 목록 렌더링.
/// 카드 탭 시 해당 플레이리스트 전체 재생.
class AutoPlaylistSection extends StatelessWidget {
  const AutoPlaylistSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AutoPlaylistProvider>(
      builder: (context, provider, _) {
        if (provider.playlists.isEmpty) {
          return const SizedBox.shrink();
        }

        final cs = AppColorScheme.of(context);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
              child: Text(
                'Smart Mixes',
                style: AppTextStyles.sectionHeader,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                itemCount: provider.playlists.length,
                itemBuilder: (context, index) {
                  final playlist = provider.playlists[index];
                  return _AutoPlaylistCard(
                    playlist: playlist,
                    cs: cs,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AutoPlaylistCard extends StatelessWidget {
  final AutoPlaylist playlist;
  final AppColorScheme cs;

  const _AutoPlaylistCard({
    required this.playlist,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: Semantics(
        label: '${playlist.label} 플레이리스트, ${playlist.tracks.length}곡',
        button: true,
        child: GestureDetector(
          onTap: () {
            final player = context.read<PlayerProvider>();
            final playAll = context.read<SettingsProvider>().settings.playAllOnTap;
            if (playAll) {
              player.playAll(playlist.tracks);
            } else {
              if (playlist.tracks.isNotEmpty) {
                player.playTrack(playlist.tracks.first);
              }
            }
          },
          child: Container(
          width: 140,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: cs.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: cs.primarySurface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Icon(
                  playlist.icon,
                  color: cs.primary,
                  size: AppSizes.iconMd,
                ),
              ),
              const Spacer(),
              Text(
                playlist.label,
                style: AppTextStyles.tileTitle.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                '${playlist.tracks.length}곡',
                style: AppTextStyles.caption.copyWith(color: cs.textTertiary),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}
