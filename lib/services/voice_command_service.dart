import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../models/voice_command.dart';

/// speech_to_text를 래핑하는 음성 명령 서비스.
///
/// 음성 인식 가용성 확인, 인식 시작/중지, 명령 파싱을 담당.
/// [CarModeScreen]에서 로컬 인스턴스로 사용.
class VoiceCommandService {
  final SpeechToText _speech = SpeechToText();
  bool _isAvailable = false;

  /// 인식 세션 종료(타임아웃·에러 포함) 시 호출.
  VoidCallback? onListeningStopped;

  /// 음성 인식 가용 여부.
  bool get isAvailable => _isAvailable;

  /// 인식 진행 중 여부.
  bool get isListening => _speech.isListening;

  /// 음성 인식 가용성 확인 및 초기화.
  Future<bool> initialize() async {
    try {
      _isAvailable = await _speech.initialize(
        onError: (error) => debugPrint('[VoiceCommandService] Error: $error'),
        onStatus: (status) {
          if (status == 'done') {
            onListeningStopped?.call();
          }
        },
      );
      return _isAvailable;
    } catch (e) {
      debugPrint('[VoiceCommandService] Init failed: $e');
      _isAvailable = false;
      return false;
    }
  }

  /// 음성 인식 시작.
  Future<void> startListening({
    required void Function(VoiceCommand) onCommand,
    void Function(String)? onPartialResult,
  }) async {
    if (!_isAvailable) return;

    await _speech.listen(
      onResult: (result) {
        final text = result.recognizedWords;
        if (text.isEmpty) return;

        if (onPartialResult != null) {
          onPartialResult(text);
        }

        if (result.finalResult) {
          final command = parseCommand(text);
          onCommand(command);
        }
      },
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 3),
      localeId: 'ko_KR',
    );
  }

  /// 음성 인식 중지.
  Future<void> stopListening() async {
    await _speech.stop();
  }

  /// 텍스트를 음성 명령으로 파싱.
  VoiceCommand parseCommand(String text) {
    final lower = text.toLowerCase().trim();

    // 재생 명령
    if (_matchesAny(lower, ['재생', '플레이', 'play', 'resume'])) {
      return const VoiceCommand(type: VoiceCommandType.play);
    }

    // 일시정지 명령
    if (_matchesAny(lower, ['정지', '일시정지', '멈춰', '스톱', 'pause', 'stop'])) {
      return const VoiceCommand(type: VoiceCommandType.pause);
    }

    // 다음 곡 명령
    if (_matchesAny(
        lower, ['다음', '다음 곡', '다음곡', '넘겨', '스킵', 'next', 'skip'])) {
      return const VoiceCommand(type: VoiceCommandType.next);
    }

    // 이전 곡 명령
    if (_matchesAny(
        lower, ['이전', '이전 곡', '이전곡', '뒤로', 'previous', 'back'])) {
      return const VoiceCommand(type: VoiceCommandType.previous);
    }

    // 검색 명령: "~틀어줘", "~재생해", "~찾아"
    final searchPatterns = [
      RegExp(r'(.+?)\s*(틀어줘|틀어|재생해|재생해줘|찾아줘|찾아|검색)'),
      RegExp(r'(play|search)\s+(.+)', caseSensitive: false),
    ];

    for (final pattern in searchPatterns) {
      final match = pattern.firstMatch(lower);
      if (match != null) {
        final query = match.group(1)?.trim() ?? match.group(2)?.trim();
        if (query != null && query.isNotEmpty) {
          return VoiceCommand(type: VoiceCommandType.search, query: query);
        }
      }
    }

    // 기본: 검색으로 처리
    return VoiceCommand(type: VoiceCommandType.search, query: text.trim());
  }

  /// 텍스트가 패턴 목록 중 하나와 매칭되는지 확인.
  bool _matchesAny(String text, List<String> patterns) {
    return patterns.any(
        (p) => text == p || text.startsWith('$p ') || text.endsWith(' $p'));
  }

  /// 리소스 해제.
  void dispose() {
    _speech.stop();
    _speech.cancel();
  }
}
