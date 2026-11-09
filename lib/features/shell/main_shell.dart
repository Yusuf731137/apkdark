import 'package:flutter/material.dart';
import '../../core/l10n/app_strings.dart';
import '../card/card_list_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../deck/deck_list_screen.dart';
import '../settings/settings_screen.dart';
import '../stats/stats_screen.dart';

class MainShell extends StatefulWidget {
  final String language;
  final ValueChanged<String> onLanguageChanged;
  const MainShell({
    super.key,
    required this.language,
    required this.onLanguageChanged,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings(widget.language);
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          DashboardScreen(strings: s),
          DeckListScreen(strings: s),
          CardListScreen(strings: s),
          StatsScreen(strings: s),
          SettingsScreen(
            strings: s,
            onLanguageChanged: widget.onLanguageChanged,
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        backgroundColor: const Color(0xFF1E1E1E),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined),
            selectedIcon: const Icon(Icons.dashboard),
            label: s.navDashboard,
          ),
          NavigationDestination(
            icon: const Icon(Icons.style_outlined),
            selectedIcon: const Icon(Icons.style),
            label: s.navDecks,
          ),
          NavigationDestination(
            icon: const Icon(Icons.credit_card_outlined),
            selectedIcon: const Icon(Icons.credit_card),
            label: s.navCards,
          ),
          NavigationDestination(
            icon: const Icon(Icons.bar_chart_outlined),
            selectedIcon: const Icon(Icons.bar_chart),
            label: s.navStats,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: s.navSettings,
          ),
        ],
      ),
    );
  }
}