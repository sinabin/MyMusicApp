import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/download_item.dart';
import '../models/voice_command.dart';
import '../providers/player_provider.dart';
import '../services/voice_command_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';

/// 차량 모드 전체 화면.
///
/// 대형 버튼 UI와 음성 명령으로 안전 운전 중 조작을 지원.
/// 화면 꺼짐 방지(WakeLock) 적용, 다크 배경 고정.
class CarModeScreen extends StatefulWidget {
  const CarModeScreen({super.key});

  @override
  State<CarModeScreen> createState() => _CarModeScreenState();
}

class _CarModeScreenState extends State<CarModeScreen> {
  final VoiceCommandService _voiceService = VoiceCommandService();
  bool _voiceAvailable = false;
  bool _isListening = false;
  String _partialText = '';

  @override
  void initState() {
    super.initState();
    // 화면 꺼짐 방지
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _initVoice();
  }

  Future<void> _initVoice() async {
    final available = await _voiceService.initialize();
    if (mounted) {
      setState(() => _voiceAvailable = available);
    }
  }

  @override
  void dispose() {
    _voiceService.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _handleVoiceCommand(VoiceCommand command) {
    final player = context.read<PlayerProvider>();

    setState(() {
      _isListening = false;
      _partialText = '';
    });

    switch (command.type) {
      case VoiceCommandType.play:
        player.resume();
      case VoiceCommandType.pause:
        player.pause();
      case VoiceCommandType.next:
        player.skipNext();
      case VoiceCommandType.previous:
        player.skipPrevious();
      case VoiceCommandType.search:
        // 차량 모드에서는 검색 미지원 (안전상 이유)
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('검색: "${command.query}"'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
    }
  }

  Future<void> _toggleVoice() async {
    if (!_voiceAvailable) return;

    if (_isListening) {
      await _voiceService.stopListening();
      if (mounted) {
        setState(() {
          _isListening = false;
          _partialText = '';
        });
      }
    } else {
      setState(() {
        _isListening = true;
        _partialText = '';
      });
      await _voiceService.startListening(
        onCommand: _handleVoiceCommand,
        onPartialResult: (text) {
          if (mounted) setState(() => _partialText = text);
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 다크 배경 고정
    return Theme(
      data: ThemeData.dark(),
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0A0F),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white70, size: 28),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.directions_car, color: Colors.white70, size: 20),
              SizedBox(width: 8),
              Text(
                '차량 모드',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ],
          ),
          centerTitle: true,
        ),
        body: Selector<PlayerProvider, DownloadItem?>(
          selector: (_, p) => p.currentTrack,
          builder: (context, track, _) {
            if (track == null) {
              return const Center(
                child: Text(
                  '재생 중인 곡이 없습니다',
                  style: TextStyle(color: Colors.white38, fontSize: 18),
                ),
              );
            }

            final title = track.fileName.endsWith('.m4a')
                ? track.fileName.substring(0, track.fileName.length - 4)
                : track.fileName;
            final artist = track.artistName ?? track.channelName ?? '';

            return SafeArea(
              child: Column(
                children: [
                  const Spacer(),

                  // 대형 앨범아트
                  _buildAlbumArt(track),
                  const SizedBox(height: AppSpacing.xxl),

                  // 곡 정보
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.xxxl),
                    child: Column(
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (artist.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxxl),

                  // 대형 컨트롤 버튼
                  _buildControls(),

                  const SizedBox(height: AppSpacing.xxl),

                  // 음성 인식 상태
                  if (_isListening) ...[
                    Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xxxl),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusMd),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Text(
                              _partialText.isEmpty
                                  ? '듣고 있습니다...'
                                  : _partialText,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 15),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const Spacer(flex: 2),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// 대형 앨범아트 빌드.
  Widget _buildAlbumArt(DownloadItem track) {
    final size = MediaQuery.of(context).size.width * 0.4;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: SizedBox(
        width: size,
        height: size,
        child: track.thumbnailUrl != null
            ? CachedNetworkImage(
                imageUrl: track.thumbnailUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => _placeholder(),
                errorWidget: (context, url, error) => _placeholder(),
              )
            : _placeholder(),
      ),
    );
  }

  /// 앨범아트 플레이스홀더.
  Widget _placeholder() {
    return Container(
      color: const Color(0xFF1A1A2E),
      child: const Icon(Icons.music_note, color: Colors.white24, size: 60),
    );
  }

  /// 대형 재생 컨트롤 빌드.
  Widget _buildControls() {
    return Selector<PlayerProvider, bool>(
      selector: (_, p) => p.isPlaying,
      builder: (context, isPlaying, _) {
        final player = context.read<PlayerProvider>();
        const buttonSize = 80.0;
        const playButtonSize = 96.0;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // 이전
              _CarModeButton(
                size: buttonSize,
                icon: Icons.skip_previous,
                iconSize: 40,
                onTap: () {
                  HapticFeedback.mediumImpact();
                  player.skipPrevious();
                },
              ),

              // 재생/일시정지
              _CarModeButton(
                size: playButtonSize,
                icon: isPlaying ? Icons.pause : Icons.play_arrow,
                iconSize: 48,
                isPrimary: true,
                onTap: () {
                  HapticFeedback.mediumImpact();
                  isPlaying ? player.pause() : player.resume();
                },
              ),

              // 다음
              _CarModeButton(
                size: buttonSize,
                icon: Icons.skip_next,
                iconSize: 40,
                onTap: () {
                  HapticFeedback.mediumImpact();
                  player.skipNext();
                },
              ),

              // 음성 (가용 시만 표시)
              if (_voiceAvailable)
                _CarModeButton(
                  size: buttonSize,
                  icon: _isListening ? Icons.mic : Icons.mic_none,
                  iconSize: 36,
                  isActive: _isListening,
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    _toggleVoice();
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

/// 차량 모드 전용 대형 원형 버튼.
class _CarModeButton extends StatelessWidget {
  /// 버튼 직경.
  final double size;

  /// 아이콘.
  final IconData icon;

  /// 아이콘 크기.
  final double iconSize;

  /// 주요 액션 여부 (그라디언트 적용).
  final bool isPrimary;

  /// 활성 상태 (음성 인식 등).
  final bool isActive;

  /// 탭 콜백.
  final VoidCallback onTap;

  const _CarModeButton({
    required this.size,
    required this.icon,
    required this.iconSize,
    this.isPrimary = false,
    this.isActive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: isPrimary ? AppColors.primaryGradient : null,
            color: isPrimary
                ? null
                : isActive
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.1),
          ),
          child: Icon(
            icon,
            color: isActive ? Colors.redAccent : Colors.white,
            size: iconSize,
          ),
        ),
      ),
    );
  }
}
