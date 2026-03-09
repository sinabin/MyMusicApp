/// 음성 명령 유형.
enum VoiceCommandType { play, pause, next, previous, search }

/// 파싱된 음성 명령 모델.
///
/// [VoiceCommandService]에서 음성 인식 결과를 파싱하여 생성.
/// [CarModeScreen]에서 [PlayerProvider] 명령으로 매핑.
class VoiceCommand {
  /// 명령 유형.
  final VoiceCommandType type;

  /// 검색 명령 시 검색어.
  final String? query;

  const VoiceCommand({required this.type, this.query});
}
