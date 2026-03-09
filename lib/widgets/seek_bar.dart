import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/player_provider.dart';
import '../theme/app_color_scheme.dart';
import '../theme/app_sizes.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../utils/format_utils.dart';

/// 재생 위치 슬라이더 위젯.
///
/// [PlayerProvider]를 구독하여 현재 위치·전체 길이를 실시간 표시.
/// 드래그로 재생 위치 탐색 지원.
/// [fullSize]가 true이면 전체 플레이어용 큰 터치 타겟 적용.
class SeekBar extends StatefulWidget {
  /// 전체 플레이어 모드 여부.
  final bool fullSize;

  const SeekBar({super.key, this.fullSize = false});

  @override
  State<SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends State<SeekBar> {
  double? _dragValue;

  @override
  Widget build(BuildContext context) {
    final cs = AppColorScheme.of(context);
    return Selector<PlayerProvider, (Duration, Duration)>(
      selector: (_, p) => (p.position, p.duration),
      builder: (context, data, _) {
        final (playerPos, playerDur) = data;
        final position = _dragValue ?? playerPos.inMilliseconds.toDouble();
        final duration = playerDur.inMilliseconds.toDouble();
        final maxVal = duration > 0 ? duration : 1.0;

        return Column(
          children: [
            SliderTheme(
              data: SliderThemeData(
                trackHeight: widget.fullSize
                    ? AppSizes.seekBarFullTrackHeight
                    : AppSizes.seekBarTrackHeight,
                thumbShape: RoundSliderThumbShape(
                  enabledThumbRadius: widget.fullSize
                      ? AppSizes.seekBarFullThumbRadius
                      : AppSizes.seekBarThumbRadius,
                ),
                overlayShape: RoundSliderOverlayShape(
                  overlayRadius: widget.fullSize
                      ? AppSizes.seekBarFullOverlayRadius
                      : AppSizes.seekBarOverlayRadius,
                ),
                activeTrackColor: cs.primary,
                inactiveTrackColor: cs.surfaceLight,
                thumbColor: cs.primaryLight,
                overlayColor: cs.primary.withValues(alpha: 0.2),
              ),
              child: Slider(
                min: 0,
                max: maxVal,
                value: position.clamp(0, maxVal),
                semanticFormatterCallback: (value) {
                  final d = Duration(milliseconds: value.toInt());
                  return FormatUtils.duration(d);
                },
                onChanged: (value) {
                  setState(() => _dragValue = value);
                },
                onChangeEnd: (value) {
                  context.read<PlayerProvider>().seekTo(
                    Duration(milliseconds: value.toInt()),
                  );
                  setState(() => _dragValue = null);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    FormatUtils.duration(playerPos),
                    style: AppTextStyles.caption.copyWith(color: cs.textTertiary),
                  ),
                  Text(
                    FormatUtils.duration(playerDur),
                    style: AppTextStyles.caption.copyWith(color: cs.textTertiary),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
