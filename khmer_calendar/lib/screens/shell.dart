import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../i18n.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/overlay_page.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.store, required this.child});
  final AppStore store;
  final Widget child;

  static const tabs = [
    (TabId.today, '/day', Icons.today, 'navToday'),
    (TabId.months, '/months', Icons.calendar_month, 'navMonth'),
    (TabId.events, '/events', Icons.event_note, 'navEvents'),
    (TabId.weather, '/weather', Icons.wb_cloudy, 'navWeather'),
    (TabId.more, '/more', Icons.menu, 'navMore'),
  ];

  @override
  Widget build(BuildContext context) {
    return WatchStore(
      store: store,
      builder: (context, store) => _ShellBody(store: store, child: child),
    );
  }
}

class _ShellBody extends StatelessWidget {
  const _ShellBody({required this.store, required this.child});
  final AppStore store;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).uri.path;
    var idx = AppShell.tabs.indexWhere((t) => loc == t.$2 || loc.startsWith('${t.$2}/'));
    if (idx < 0) idx = 1;
    final wide = MediaQuery.sizeOf(context).width >= wideBreak;

    void go(int i) {
      store.setLastTab(AppShell.tabs[i].$1);
      context.go(AppShell.tabs[i].$2);
    }

    if (wide) {
      return Scaffold(
        body: SafeArea(
          child: Row(
            children: [
              NavigationRail(
                selectedIndex: idx,
                onDestinationSelected: go,
                labelType: NavigationRailLabelType.all,
                destinations: [
                  for (final tab in AppShell.tabs)
                    NavigationRailDestination(
                      icon: Icon(tab.$3),
                      selectedIcon: Icon(tab.$3),
                      label: Text(t(store.lang, tab.$4)),
                    ),
                ],
              ),
              const VerticalDivider(width: 1),
              Expanded(child: child),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(child: child),
      bottomNavigationBar: NavigationBar(
        selectedIndex: idx,
        onDestinationSelected: go,
        destinations: [
          for (final tab in AppShell.tabs)
            NavigationDestination(
              icon: Icon(tab.$3),
              selectedIcon: Icon(tab.$3),
              label: t(store.lang, tab.$4),
            ),
        ],
      ),
    );
  }
}
