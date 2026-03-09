import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import 'discover_screen.dart';
import 'home_screen.dart';
import 'library_screen.dart';

/// 탭 네비게이션 셸.
///
/// [NavigationBar] (Material 3)로 Home / Discover / Library 3개 탭을 제공.
/// [IndexedStack]으로 탭 상태 보존.
/// 미니 플레이어는 [App.builder]에서 글로벌로 표시.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _currentIndex = 0);
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: const [
            HomeScreen(),
            DiscoverScreen(),
            LibraryScreen(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            if (index != _currentIndex) {
              HapticFeedback.selectionClick();
            }
            setState(() => _currentIndex = index);
          },
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home),
              label: L.of(context)!.tabHome,
            ),
            NavigationDestination(
              icon: const Icon(Icons.explore_outlined),
              selectedIcon: const Icon(Icons.explore),
              label: L.of(context)!.tabDiscover,
            ),
            NavigationDestination(
              icon: const Icon(Icons.library_music_outlined),
              selectedIcon: const Icon(Icons.library_music),
              label: L.of(context)!.tabLibrary,
            ),
          ],
        ),
      ),
    );
  }
}
