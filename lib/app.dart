import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/providers/theme_provider.dart';
import 'core/theme/theme_engine.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/market_data/presentation/screens/market_watch_screen.dart';
import 'features/charting/presentation/screens/chart_screen.dart';
import 'features/signals/presentation/screens/signal_list_screen.dart';
import 'features/signals/presentation/screens/signal_detail_screen.dart';
import 'features/signals/presentation/screens/signal_dashboard_screen.dart';
import 'features/news/presentation/screens/news_calendar_screen.dart';
import 'features/ai_agent/presentation/screens/ai_chat_screen.dart';
import 'features/trading/presentation/screens/portfolio_screen.dart';
import 'features/settings/presentation/screens/settings_screen.dart';
import 'shared/widgets/main_scaffold.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final themeMode = ref.watch(themeModeProvider);

  return GoRouter(
    initialLocation: '/signals',
    routes: [
      ShellRoute(
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(
            path: '/market',
            name: 'market',
            pageBuilder: (context, state) => NoTransitionPage(
              child: const MarketWatchScreen(),
              key: state.pageKey,
            ),
          ),
          GoRoute(
            path: '/chart',
            name: 'chart',
            pageBuilder: (context, state) => NoTransitionPage(
              child: const ChartScreen(),
              key: state.pageKey,
            ),
          ),
          GoRoute(
            path: '/signals',
            name: 'signals',
            pageBuilder: (context, state) => NoTransitionPage(
              child: const SignalListScreen(),
              key: state.pageKey,
            ),
          ),
          GoRoute(
            path: '/dashboard',
            name: 'dashboard',
            pageBuilder: (context, state) => NoTransitionPage(
              child: const SignalDashboardScreen(),
              key: state.pageKey,
            ),
          ),
          GoRoute(
            path: '/news',
            name: 'news',
            pageBuilder: (context, state) => NoTransitionPage(
              child: const NewsCalendarScreen(),
              key: state.pageKey,
            ),
          ),
          GoRoute(
            path: '/ai',
            name: 'ai',
            pageBuilder: (context, state) => NoTransitionPage(
              child: const AiChatScreen(),
              key: state.pageKey,
            ),
          ),
          GoRoute(
            path: '/portfolio',
            name: 'portfolio',
            pageBuilder: (context, state) => NoTransitionPage(
              child: const PortfolioScreen(),
              key: state.pageKey,
            ),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            pageBuilder: (context, state) => NoTransitionPage(
              child: const SettingsScreen(),
              key: state.pageKey,
            ),
          ),
          GoRoute(
            path: '/signal/:id',
            name: 'signalDetail',
            builder: (context, state) => SignalDetailScreen(
              signalId: state.pathParameters['id']!,
            ),
          ),
        ],
      ),
    ],
  );
});

class ForexSignalProApp extends ConsumerWidget {
  const ForexSignalProApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeEngineProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: themeMode.lightTheme,
      darkTheme: themeMode.darkTheme,
      themeMode: themeMode.mode,
      routerConfig: router,
    );
  }
}
