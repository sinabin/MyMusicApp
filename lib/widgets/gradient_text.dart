import 'package:flutter/material.dart';

/// 그라데이션이 적용된 텍스트를 렌더링하는 위젯.
///
/// [ShaderMask]를 사용하여 [gradient]를 텍스트에 적용.
/// [HomeScreen]의 히어로 타이틀에 사용.
class GradientText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final Gradient gradient;

  const GradientText({
    super.key,
    required this.text,
    required this.style,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: text,
      child: ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (bounds) => gradient.createShader(
          Rect.fromLTWH(0, 0, bounds.width, bounds.height),
        ),
        child: Text(text, style: style),
      ),
    );
  }
}
