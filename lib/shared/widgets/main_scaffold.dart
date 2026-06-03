import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MainScaffold extends ConsumerWidget {
  final Widget child;
  const MainScaffold({super.key, required this.child});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/market')) return 0;
    if (location.startsWith('/chart')) return 1;
    if (location.startsWith('/dashboard')) return 2;
    if (location.startsWith('/signals')) return 3;
    if (location.startsWith('/news')) return 4;
    if (location.startsWith('/ai')) return 5;
    if (location.startsWith('/portfolio')) return 6;
    if (location.startsWith('/settings')) return 7;
    return 3;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final index = _currentIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        onTap: (i) {
          switch (i) {
            case 0: context.go('/market');
            case 1: context.go('/chart');
            case 2: context.go('/dashboard');
            case 3: context.go('/signals');
            case 4: context.go('/news');
            case 5: context.go('/ai');
            case 6: context.go('/portfolio');
            case 7: context.go('/settings');
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: theme.colorScheme.primary,
        unselectedItemColor: theme.colorScheme.onSurface.withValues(alpha: 0.5),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.monitor_heart_outlined), label: 'Market'),
          BottomNavigationBarItem(icon: Icon(Icons.show_chart), label: 'Chart'),
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_active), label: 'Signals'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'News'),
          BottomNavigationBarItem(icon: Icon(Icons.auto_awesome), label: 'AI'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Portfolio'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
