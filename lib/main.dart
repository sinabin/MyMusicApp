import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'data/download_history_db.dart';
import 'data/local_storage.dart';
import 'providers/download_provider.dart';
import 'providers/history_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/video_info_provider.dart';
import 'services/audio_converter_service.dart';
import 'services/auth_service.dart';
import 'services/download_service.dart';
import 'services/file_service.dart';
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

  final youtubeService = YouTubeService();
  final authService = AuthService();
  final fileService = FileService();
  final localStorage = LocalStorage();
  final downloadService = DownloadService(youtubeService);
  final converterService = AudioConverterService();

  runApp(
    MultiProvider(
      providers: [
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
          create: (_) => DownloadProvider(
            downloadService: downloadService,
            converterService: converterService,
            fileService: fileService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => HistoryProvider(db: downloadHistoryDb),
        ),
      ],
      child: const App(),
    ),
  );
}
