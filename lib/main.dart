import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'data/dismissed_recommendation_db.dart';
import 'data/download_history_db.dart';
import 'data/local_storage.dart';
import 'data/playback_history_db.dart';
import 'data/playlist_db.dart';
import 'providers/download_provider.dart';
import 'providers/history_provider.dart';
import 'providers/playback_history_provider.dart';
import 'providers/player_provider.dart';
import 'providers/playlist_provider.dart';
import 'providers/recommendation_provider.dart';
import 'providers/search_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/video_info_provider.dart';
import 'services/audio_converter_service.dart';
import 'services/audio_handler.dart';
import 'services/audio_player_service.dart';
import 'services/auth_service.dart';
import 'services/download_service.dart';
import 'services/file_service.dart';
import 'services/recommendation/recommendation_service.dart';
import 'services/youtube_service.dart';

/// 앱 진입점.
///
/// 서비스 및 데이터베이스를 초기화하고 [MultiProvider]로 의존성을 주입한 뒤
/// [App] 위젯을 실행.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Status bar style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF0D0D1A),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // Initialize services
  final downloadHistoryDb = DownloadHistoryDb();
  await downloadHistoryDb.init();

  final dismissedDb = DismissedRecommendationDb();
  await dismissedDb.init();
  await dismissedDb.cleanup();

  final playlistDb = PlaylistDb();
  await playlistDb.init();

  final playbackHistoryDb = PlaybackHistoryDb();
  await playbackHistoryDb.init();
  await playbackHistoryDb.cleanup();

  final youtubeService = YouTubeService();
  final authService = AuthService();
  final fileService = FileService();
  final localStorage = LocalStorage();
  final downloadService = DownloadService(youtubeService);
  final converterService = AudioConverterService();

  final recommendationService = RecommendationService(
    youtubeService: youtubeService,
    downloadHistoryDb: downloadHistoryDb,
    dismissedDb: dismissedDb,
  );

  // Initialize AudioService
  final audioHandler = await AudioService.init(
    builder: () => MyAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.example.mymusicapp.audio',
      androidNotificationChannelName: 'Music playback',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );

  // Configure audio session
  final session = await AudioSession.instance;
  await session.configure(const AudioSessionConfiguration.music());

  final audioPlayerService = AudioPlayerService(audioHandler);

  final playbackHistoryProvider = PlaybackHistoryProvider(
    db: playbackHistoryDb,
    downloadDb: downloadHistoryDb,
  );

  runApp(
    MultiProvider(
      providers: [
        Provider<YouTubeService>.value(value: youtubeService),
        Provider<AuthService>.value(value: authService),
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(
            localStorage: localStorage,
            authService: authService,
            fileService: fileService,
          )..init(),
        ),
        ChangeNotifierProvider(
          create: (_) => VideoInfoProvider(youtubeService: youtubeService),
        ),
        ChangeNotifierProvider(
          create: (_) => SearchProvider(youtubeService: youtubeService),
        ),
        ChangeNotifierProvider(
          create: (_) => DownloadProvider(
            downloadService: downloadService,
            converterService: converterService,
            fileService: fileService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => HistoryProvider(
            db: downloadHistoryDb,
            localStorage: localStorage,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => RecommendationProvider(
            service: recommendationService,
            dismissedDb: dismissedDb,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => PlayerProvider(
            audioPlayerService: audioPlayerService,
            onTrackPlayed: (videoId) =>
                playbackHistoryProvider.recordPlay(videoId),
          ),
        ),
        ChangeNotifierProvider.value(value: playbackHistoryProvider),
        ChangeNotifierProvider(
          create: (_) => PlaylistProvider(
            db: playlistDb,
            downloadDb: downloadHistoryDb,
          ),
        ),
      ],
      child: const App(),
    ),
  );
}
