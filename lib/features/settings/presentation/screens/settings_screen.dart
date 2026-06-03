import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/theme/theme_engine.dart';
import '../../../../core/theme/providers/theme_provider.dart';
import '../../../signals/data/signal_repository.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentTheme = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Appearance', style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          _SettingsCard(children: [
            ListTile(
              leading: const Icon(Icons.palette),
              title: const Text('Theme'),
              subtitle: Text(_themeName(currentTheme)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showThemePicker(context, ref),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.brightness_6),
              title: const Text('Dark Mode'),
              trailing: Switch(
                value: theme.brightness == Brightness.dark,
                onChanged: (_) => ref.read(themeModeProvider.notifier).toggleBrightness(ref),
              ),
            ),
          ]),
          const SizedBox(height: 24),
          Text('Trading', style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          _SettingsCard(children: [
            ListTile(
              leading: const Icon(Icons.account_balance),
              title: const Text('Deriv Account'),
              subtitle: const Text('Not connected'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.api),
              title: const Text('API Connection'),
              subtitle: const Text('Deriv WebSocket'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
          ]),
          const SizedBox(height: 24),
          Text('AI Agent', style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          _SettingsCard(children: [
            ListTile(
              leading: const Icon(Icons.smart_toy),
              title: const Text('LLM Model'),
              subtitle: const Text('GGUF model (.gguf, 2-8 GB)'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.psychology),
              title: const Text('Neural Network'),
              subtitle: const Text('Self-optimization enabled'),
              trailing: Switch(value: true, onChanged: (_) {}),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.tune),
              title: const Text('Self-Fix Threshold'),
              subtitle: const Text('15% failure rate trigger'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
          ]),
          const SizedBox(height: 24),
          Text('Signals', style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          _SettingsCard(children: [
            ListTile(
              leading: const Icon(Icons.tune),
              title: const Text('Signal Filters'),
              subtitle: const Text('Min confidence: 50%, Min confluence: 3'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Notifications'),
              subtitle: const Text('New signals, SL/TP hits'),
              trailing: Switch(value: true, onChanged: (_) {}),
            ),
          ]),
          const SizedBox(height: 24),
          Text('News', style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          _SettingsCard(children: [
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Forex Factory Scraper'),
              subtitle: const Text('Every 60 minutes, SAST timezone'),
              trailing: Switch(value: true, onChanged: (_) {}),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.warning_amber),
              title: const Text('News-Adjust Signals'),
              subtitle: const Text('Reduce confidence near high-impact events'),
              trailing: Switch(value: true, onChanged: (_) {}),
            ),
          ]),
          const SizedBox(height: 24),
          Text('Data', style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          _SettingsCard(children: [
            ListTile(
              leading: const Icon(Icons.delete_sweep),
              title: const Text('Clear Signal History'),
              subtitle: const Text('Remove all stored signals'),
              onTap: () => _confirmClearData(context, ref),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.file_download),
              title: const Text('Export Data'),
              subtitle: const Text('CSV format'),
              onTap: () => _exportData(context),
            ),
          ]),
          const SizedBox(height: 24),
          _SettingsCard(children: [
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Forex Signal Pro v0.1.0'),
              subtitle: const Text('Open Source - MIT License'),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.code),
              title: const Text('Source Code'),
              subtitle: const Text('github.com/anomalyco/forex_signal_pro'),
              onTap: () {},
            ),
          ]),
          const SizedBox(height: 16),
          Text(
            'RISK DISCLAIMER: Trading forex carries significant financial risk. '
            'This application provides technical signals based on historical data and '
            'technical analysis. Past performance does not guarantee future results. '
            'Never trade with money you cannot afford to lose.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _themeName(AppTheme theme) {
    switch (theme) {
      case AppTheme.professionalDark: return 'Professional Dark';
      case AppTheme.liquidGlass: return 'Liquid Glass';
      case AppTheme.light: return 'Light';
      case AppTheme.highContrast: return 'High Contrast';
    }
  }

  void _showThemePicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: AppTheme.values.map((theme) {
          return ListTile(
            leading: Icon(_themeIcon(theme)),
            title: Text(_themeName(theme)),
            subtitle: Text(_themeDesc(theme)),
            trailing: ref.watch(themeModeProvider) == theme
                ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                : null,
            onTap: () {
              ref.read(themeModeProvider.notifier).setTheme(theme);
              Navigator.pop(ctx);
            },
          );
        }).toList(),
      ),
    );
  }

  IconData _themeIcon(AppTheme theme) {
    switch (theme) {
      case AppTheme.professionalDark: return Icons.dark_mode;
      case AppTheme.liquidGlass: return Icons.blur_on;
      case AppTheme.light: return Icons.light_mode;
      case AppTheme.highContrast: return Icons.contrast;
    }
  }

  String _themeDesc(AppTheme theme) {
    switch (theme) {
      case AppTheme.professionalDark: return 'Dark trading-optimized theme';
      case AppTheme.liquidGlass: return 'iOS 26-style glassmorphism';
      case AppTheme.light: return 'Clean white & blue theme';
      case AppTheme.highContrast: return 'Maximum readability';
    }
  }

  void _confirmClearData(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Signal History'),
        content: const Text('This will permanently delete all stored signals and performance data. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(signalRepositoryProvider).clearSignals();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Signal history cleared'), backgroundColor: Colors.green),
                );
              }
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _exportData(BuildContext context) async {
    await SharePlus.instance.share(
      ShareParams(text: 'Forex Signal Pro - Trading Performance Export'),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}
