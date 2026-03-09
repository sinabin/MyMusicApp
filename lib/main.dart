import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'data/dismissed_recommendation_db.dart';
import 'data/download_history_db.dart';
import 'data/local_storage.dart';
import 'data/lyrics_db.dart';
import 'data/playback_history_db.dart';
import 'data/playlist_db.dart';
import 'providers/artist_explorer_provider.dart';
import 'providers/auto_playlist_provider.dart';
import 'providers/download_provider.dart';
import 'providers/history_provider.dart';
import 'providers/lyrics_provider.dart';
import 'providers/playback_history_provider.dart';
import 'providers/player_provider.dart';
import 'providers/playlist_provider.dart';
import 'providers/premium_provider.dart';
import 'providers/recommendation_provider.dart';
import 'providers/search_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/video_info_provider.dart';
import 'services/artist_explorer_service.dart';
import 'services/audio_converter_service.dart';
import 'services/audio_handler.dart';
import 'services/audio_player_service.dart';
import 'services/auth_service.dart';
import 'services/classification/auto_playlist_service.dart';
import 'services/classification/track_classifier_service.dart';
import 'services/download_service.dart';
import 'services/file_service.dart';
import 'services/lyrics_service.dart';
import 'services/premium_service.dart';
import 'services/recommendation/recommendation_service.dart';
import 'services/youtube_service.dart';

/// 앱 진입점.
///
/// 서비스 및 데이터베이스를 초기화하고 [MultiProvider]로 의존성을 주입한 뒤
/// [App] 위젯을 실행.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Status bar style (테마에 맞춰 app.dart에서 재설정)
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
  ));

  // Initialize databases
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

  final lyricsDb = LyricsDb();
  await lyricsDb.init();
  await lyricsDb.cleanup();

  // Initialize core services
  final authService = AuthService();
  final youtubeService = YouTubeService(authService: authService);
  final fileService = FileService();
  await fileService.getThumbnailDir();
  final localStorage = LocalStorage();
  final downloadService = DownloadService(youtubeService);
  final converterService = AudioConverterService();

  final recommendationService = RecommendationService(
    youtubeService: youtubeService,
    downloadHistoryDb: downloadHistoryDb,
    dismissedDb: dismissedDb,
  );

  // Phase 2: Classification services
  final classifierService = TrackClassifierService();
  final autoPlaylistService = AutoPlaylistService(classifierService);

  // Phase 3: Lyrics service
  final lyricsService = LyricsService(db: lyricsDb);

  // Phase 4: Artist explorer service
  final artistExplorerService = ArtistExplorerService(
    youtubeService: youtubeService,
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

  // Phase 0: SettingsProvider (필요한 다른 Provider보다 먼저 생성)
  final settingsProvider = SettingsProvider(
    localStorage: localStorage,
    authService: authService,
    fileService: fileService,
    youtubeService: youtubeService,
  )..init();

  // Phase 0: Premium service
  final premiumService = PremiumService(
    localStorage: localStorage,
    settingsProvider: settingsProvider,
  );
  await premiumService.initialize();

  // Phase 1: Recommendation provider with playback history
  final recommendationProvider = RecommendationProvider(
    service: recommendationService,
    dismissedDb: dismissedDb,
  )..setPlaybackHistoryDb(playbackHistoryDb);

  runApp(
    MultiProvider(
      providers: [
        Provider<YouTubeService>.value(value: youtubeService),
        Provider<AuthService>.value(value: authService),
        Provider<FileService>.value(value: fileService),
        ChangeNotifierProvider.value(value: settingsProvider),
        ChangeNotifierProvider(
          create: (_) => PremiumProvider(
            service: premiumService,
            settingsProvider: settingsProvider,
          ),
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
        ChangeNotifierProvider.value(value: recommendationProvider),
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
        ChangeNotifierProvider(
          create: (_) => AutoPlaylistProvider(service: autoPlaylistService),
        ),
        ChangeNotifierProvider(
          create: (_) => LyricsProvider(service: lyricsService),
        ),
        ChangeNotifierProvider(
          create: (_) => ArtistExplorerProvider(service: artistExplorerService),
        ),
      ],
      child: const App(),
    ),
  );
}
