import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/signal_repository.dart';
import '../../domain/models/signal_entity.dart';
import '../../domain/neural_tracker/feature_extractor.dart';
import '../../domain/neural_tracker/network.dart';
import '../../domain/neural_tracker/self_fix_engine.dart';
import '../../domain/neural_tracker/failure_analyzer.dart';

final signalStatsProvider = FutureProvider<SignalStats>((ref) async {
  final repo = ref.watch(signalRepositoryProvider);
  final signals = await repo.getSignals();
  return SignalStats.fromSignals(signals);
});

final featureImportanceProvider = FutureProvider<List<double>>((ref) async {
  final repo = ref.watch(signalRepositoryProvider);
  final signals = await repo.getSignals();
  if (signals.isEmpty) return List.filled(FeatureExtractor.featureNames.length, 0.5);
  final nn = SignalScoringNN.defaultConfig();
  final closed = signals.where((s) => s.closedAt != null).toList();
  if (closed.isNotEmpty) {
    final examples = closed.map((s) {
      final features = FeatureExtractor.fromSignal(s, historicalWinrate: 0.5);
      final label = s.status == SignalStatus.tpHit ? 1.0 : 0.0;
      return TrainingExample(features: features.toNormalizedList(), label: label);
    }).toList();
    if (examples.length >= 5) nn.train(examples, epochs: 3);
  }
  final sample = FeatureExtractor.fromSignal(
    signals.last, historicalWinrate: 0.5,
  );
  return nn.featureImportance(baselineFeatures: sample.toNormalizedList(), samples: 30);
});

class SignalStats {
  final int total;
  final int active;
  final int wins;
  final int losses;
  final double winRate;
  final double avgConfidence;
  final double avgConfluence;
  final int selfFixesApplied;

  const SignalStats({
    required this.total,
    required this.active,
    required this.wins,
    required this.losses,
    required this.winRate,
    required this.avgConfidence,
    required this.avgConfluence,
    required this.selfFixesApplied,
  });

  factory SignalStats.fromSignals(List<SignalEntity> signals) {
    final closed = signals.where((s) => s.closedAt != null).toList();
    final wins = closed.where((s) => s.status == SignalStatus.tpHit).length;
    final losses = closed.where((s) => s.status == SignalStatus.slHit).length;
    double avgConf = 0;
    double avgConf2 = 0;
    if (signals.isNotEmpty) {
      avgConf = signals.fold(0.0, (a, s) => a + s.confidence) / signals.length;
      avgConf2 = signals.fold(0.0, (a, s) => a + s.confluenceCount) / signals.length;
    }
    return SignalStats(
      total: signals.length,
      active: signals.where((s) => s.status == SignalStatus.active).length,
      wins: wins,
      losses: losses,
      winRate: closed.isEmpty ? 0 : wins / closed.length,
      avgConfidence: avgConf,
      avgConfluence: avgConf2,
      selfFixesApplied: 0,
    );
  }
}

class SignalDashboardScreen extends ConsumerWidget {
  const SignalDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final statsAsync = ref.watch(signalStatsProvider);
    final importanceAsync = ref.watch(featureImportanceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Signal Dashboard')),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text('Could not load stats', style: theme.textTheme.bodyLarge),
              TextButton(onPressed: () => ref.invalidate(signalStatsProvider), child: const Text('Retry')),
            ],
          ),
        ),
        data: (stats) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PerformanceGauge(winRate: stats.winRate, theme: theme),
              const SizedBox(height: 24),
              Text('Overview', style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              Row(
                children: [
                  _StatCard(label: 'Total Signals', value: '${stats.total}', icon: Icons.timeline, theme: theme),
                  const SizedBox(width: 12),
                  _StatCard(label: 'Active', value: '${stats.active}', icon: Icons.play_arrow, theme: theme),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _StatCard(label: 'Wins', value: '${stats.wins}', icon: Icons.check_circle, theme: theme, color: Colors.green),
                  const SizedBox(width: 12),
                  _StatCard(label: 'Losses', value: '${stats.losses}', icon: Icons.cancel, theme: theme, color: Colors.red),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _StatCard(label: 'Avg Confidence', value: '${(stats.avgConfidence * 100).toStringAsFixed(0)}%', icon: Icons.trending_up, theme: theme),
                  const SizedBox(width: 12),
                  _StatCard(label: 'Avg Confluence', value: stats.avgConfluence.toStringAsFixed(1), icon: Icons.groups, theme: theme),
                ],
              ),
              const SizedBox(height: 24),
              Text('Self-Optimization', style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.auto_fix_high, size: 32, color: theme.colorScheme.primary),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Self-Fixes Applied', style: theme.textTheme.titleMedium),
                            const SizedBox(height: 4),
                            Text('${stats.selfFixesApplied} automatic adjustments to improve signal quality', style: theme.textTheme.bodyMedium),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text('Feature Importance', style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      ...importanceAsync.when(
                        loading: () => [const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(strokeWidth: 2)))],
                        error: (_, __) => [Text('Could not compute importances', style: theme.textTheme.bodySmall)],
                        data: (importances) => List.generate(
                          importances.length > 10 ? 10 : importances.length,
                          (i) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 140,
                                  child: Text(
                                    i < FeatureExtractor.featureNames.length ? FeatureExtractor.featureNames[i] : 'Feature $i',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ),
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: i < importances.length ? importances[i] : 0,
                                      minHeight: 8,
                                      backgroundColor: Colors.grey.withValues(alpha: 0.2),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 40,
                                  child: Text(
                                    ' ${(i < importances.length ? importances[i] * 100 : 0).toStringAsFixed(0)}%',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PerformanceGauge extends StatelessWidget {
  final double winRate;
  final ThemeData theme;
  const _PerformanceGauge({required this.winRate, required this.theme});

  @override
  Widget build(BuildContext context) {
    final color = winRate >= 0.7 ? Colors.green : winRate >= 0.5 ? Colors.orange : Colors.red;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: SizedBox(
            width: 140,
            height: 140,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 140,
                  height: 140,
                  child: CircularProgressIndicator(
                    value: winRate,
                    strokeWidth: 10,
                    backgroundColor: Colors.grey.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${(winRate * 100).toStringAsFixed(0)}%',
                        style: theme.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold)),
                    Text('Win Rate', style: theme.textTheme.bodyMedium),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final ThemeData theme;
  final Color? color;
  const _StatCard({required this.label, required this.value, required this.icon, required this.theme, this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color ?? theme.colorScheme.primary, size: 24),
              const SizedBox(height: 8),
              Text(value, style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: color)),
              Text(label, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}
