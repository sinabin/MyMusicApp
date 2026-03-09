import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'l10n/app_localizations.dart';
import 'providers/settings_provider.dart';
import 'screens/main_shell.dart';
import 'theme/app_color_scheme.dart';
import 'theme/app_theme.dart';
import 'widgets/mini_player.dart';

/// 앱 전역 [NavigatorState] 접근용 키.
///
/// [MiniPlayer]처럼 [MaterialApp.builder] 내부(Navigator 바깥)에서
/// 라우트를 푸시할 때 사용.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

/// 앱의 루트 위젯.
///
/// [AppTheme.darkTheme]을 적용하고 [MainShell]을 초기 화면으로 표시.
/// [MaterialApp.builder]를 통해 [MiniPlayer]를 모든 화면 하단에 글로벌 표시.
/// [SafeArea]로 시스템 네비게이션 바 위에 배치.
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<SettingsProvider, ThemeMode>(
      selector: (_, p) => p.settings.themeMode,
      builder: (context, themeMode, _) {
        return MaterialApp(
          title: 'MyMusicApp',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          localizationsDelegates: L.localizationsDelegates,
          supportedLocales: L.supportedLocales,
          locale: const Locale('ko'),
          navigatorKey: appNavigatorKey,
          home: const MainShell(),
          builder: (context, child) {
            final cs = AppColorScheme.of(context);
            return ColoredBox(
              color: cs.scaffoldBackground,
              child: SafeArea(
                top: false,
                child: Column(
                  children: [
                    Expanded(child: child!),
                    const MiniPlayer(),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
