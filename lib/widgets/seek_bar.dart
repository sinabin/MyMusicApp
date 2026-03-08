import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/player_provider.dart';
import '../theme/app_colors.dart';
import '../utils/format_utils.dart';

/// 재생 위치 슬라이더 위젯.
///
/// [PlayerProvider]를 구독하여 현재 위치·전체 길이를 실시간 표시.
/// 드래그로 재생 위치 탐색 지원.
class SeekBar extends StatefulWidget {
  const SeekBar({super.key});

  @override
  State<SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends State<SeekBar> {
  double? _dragValue;

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, player, _) {
        final position = _dragValue ?? player.position.inMilliseconds.toDouble();
        final duration = player.duration.inMilliseconds.toDouble();
        final maxVal = duration > 0 ? duration : 1.0;

        return Column(
          children: [
            SliderTheme(
              data: SliderThemeData(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                activeTrackColor: AppColors.primary,
                inactiveTrackColor: AppColors.surfaceLight,
                thumbColor: AppColors.primaryLight,
                overlayColor: AppColors.primary.withValues(alpha: 0.2),
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
                  player.seekTo(Duration(milliseconds: value.toInt()));
                  setState(() => _dragValue = null);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    FormatUtils.duration(player.position),
                    style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    FormatUtils.duration(player.duration),
                    style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 12,
                    ),
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
