import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_color_scheme.dart';
import '../theme/app_durations.dart';
import '../theme/app_sizes.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import '../utils/url_validator.dart';

/// YouTube URL 입력 필드 위젯.
///
/// 붙여넣기·지우기 버튼과 실시간 유효성 검증 피드백을 제공.
/// [UrlValidator]로 URL을 검증하고, 유효한 영상 ID를 [onUrlValid] 콜백으로 전달.
class UrlInputField extends StatefulWidget {
  final ValueChanged<String> onUrlChanged;
  final ValueChanged<String>? onUrlValid;
  final VoidCallback? onUrlCleared;

  const UrlInputField({
    super.key,
    required this.onUrlChanged,
    this.onUrlValid,
    this.onUrlCleared,
  });

  @override
  State<UrlInputField> createState() => _UrlInputFieldState();
}

class _UrlInputFieldState extends State<UrlInputField> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _isFocused = false;
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    final videoId = UrlValidator.extractVideoId(value);
    setState(() => _isValid = videoId != null);
    widget.onUrlChanged(value);
    if (videoId != null) {
      widget.onUrlValid?.call(videoId);
    }
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.isNotEmpty) {
      _controller.text = data.text!;
      _onChanged(data.text!);
    }
  }

  void _clear() {
    _controller.clear();
    setState(() => _isValid = false);
    widget.onUrlChanged('');
    widget.onUrlCleared?.call();
  }

  @override
  Widget build(BuildContext context) {
    final cs = AppColorScheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: AppDurations.normal,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: cs.primaryLight.withValues(alpha: 0.3),
                      blurRadius: 12,
                      spreadRadius: 0,
                    ),
                  ]
                : [],
          ),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            onChanged: _onChanged,
            style: TextStyle(color: cs.textPrimary, fontSize: 16),
            decoration: InputDecoration(
              hintText: 'YouTube URL 붙여넣기...',
              prefixIcon: const Icon(
                Icons.play_circle_fill,
                color: Color(0xFFFF0000),
                size: AppSizes.iconXl,
              ),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.content_paste, color: cs.textSecondary),
                    onPressed: _paste,
                    tooltip: '붙여넣기',
                  ),
                  if (_controller.text.isNotEmpty)
                    IconButton(
                      icon: Icon(Icons.close, color: cs.textSecondary),
                      onPressed: _clear,
                      tooltip: '지우기',
                    ),
                ],
              ),
            ),
          ),
        ),
        if (_controller.text.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(
                _isValid ? Icons.check_circle : Icons.error_outline,
                size: AppSizes.iconSm,
                color: _isValid ? cs.success : cs.error,
              ),
              const SizedBox(width: 6),
              Text(
                _isValid ? '유효한 YouTube URL' : '유효하지 않은 URL',
                style: TextStyle(
                  fontSize: 12,
                  color: _isValid ? cs.success : cs.error,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
