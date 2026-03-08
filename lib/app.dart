import 'package:flutter/material.dart';
import 'screens/main_shell.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';
import 'widgets/mini_player.dart';

/// 앱의 루트 위젯.
///
/// [AppTheme.darkTheme]을 적용하고 [MainShell]을 초기 화면으로 표시.
/// [MaterialApp.builder]를 통해 [MiniPlayer]를 모든 화면 하단에 글로벌 표시.
/// [SafeArea]로 시스템 네비게이션 바 위에 배치.
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyMusicApp',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const MainShell(),
      builder: (context, child) {
        return ColoredBox(
          color: AppColors.scaffoldBackground,
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
  }
}
