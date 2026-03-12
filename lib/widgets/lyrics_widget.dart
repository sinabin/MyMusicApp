import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../providers/lyrics_provider.dart';
import '../providers/player_provider.dart';
import '../theme/app_color_scheme.dart';
import '../theme/app_sizes.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';

/// 가사를 표시하는 위젯.
///
/// [LyricsProvider]를 구독하여 로딩/미발견/정상 상태별 UI 표시.
/// [FullPlayerScreen]에서 앨범아트 대신 조건부로 표시.
class LyricsWidget extends StatelessWidget {
  const LyricsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = AppColorScheme.of(context);

    return Consumer<LyricsProvider>(
      builder: (context, provider, _) {
        // 로딩 중
        if (provider.isLoading) {
          return _buildShimmer(cs);
        }

        // 가사 미발견
        if (provider.notFound) {
          return _buildNotFound(context, cs, provider);
        }

        // 가사 표시
        if (provider.lyrics != null) {
          return Container(
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: SelectableText(
                provider.lyrics!,
                style: TextStyle(
                  color: cs.textPrimary,
                  fontSize: 16,
                  height: 2.0,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          );
        }

        // 초기 상태 (아직 로딩 시작 전)
        return Center(
          child: Text(
            '가사 버튼을 눌러 가사를 불러오세요',
            style: TextStyle(color: cs.textTertiary, fontSize: 14),
          ),
        );
      },
    );
  }

  /// 가사 미발견 상태 UI.
  Widget _buildNotFound(
    BuildContext context,
    AppColorScheme cs,
    LyricsProvider provider,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lyrics_outlined,
              color: cs.textTertiary,
              size: AppSizes.iconHero,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              '가사를 찾을 수 없습니다',
              style: TextStyle(
                color: cs.textSecondary,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '이 곡의 가사 정보가 아직 등록되지 않았습니다',
              style: TextStyle(
                color: cs.textTertiary,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            TextButton.icon(
              onPressed: () {
                final track =
                    context.read<PlayerProvider>().currentTrack;
                if (track != null) {
                  provider.retryLyrics(track);
                }
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('다시 검색'),
              style: TextButton.styleFrom(
                foregroundColor: cs.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 로딩 중 시머 효과 표시.
  Widget _buildShimmer(AppColorScheme cs) {
    return Shimmer.fromColors(
      baseColor: cs.surface,
      highlightColor: cs.surfaceVariant,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(
            8,
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Container(
                height: 16,
                width: i % 3 == 0 ? 180 : (i % 2 == 0 ? 240 : 200),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
