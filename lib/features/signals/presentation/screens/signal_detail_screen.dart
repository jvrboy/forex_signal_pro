import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/signal_repository.dart';
import '../../domain/models/signal_entity.dart';
import '../../domain/neural_tracker/failure_analyzer.dart';
import '../../domain/neural_tracker/network.dart';
import '../../domain/neural_tracker/feature_extractor.dart';

final signalDetailProvider = FutureProvider.family<SignalEntity?, String>((ref, id) async {
  final repo = ref.watch(signalRepositoryProvider);
  return repo.getSignal(id);
});

final signalFailureReportProvider = FutureProvider.family<FailureReport?, String>((ref, id) async {
  final repo = ref.watch(signalRepositoryProvider);
  final signal = await repo.getSignal(id);
  if (signal == null || signal.status != SignalStatus.slHit) return null;
  final nn = SignalScoringNN.defaultConfig();
  final analyzer = FailureAnalyzer(nn: nn);
  return analyzer.analyze(signal);
});

class SignalDetailScreen extends ConsumerWidget {
  final String signalId;
  const SignalDetailScreen({super.key, required this.signalId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final signalAsync = ref.watch(signalDetailProvider(signalId));
    final reportAsync = ref.watch(signalFailureReportProvider(signalId));

    return signalAsync.when(
      loading: () => Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator())),
      error: (err, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Error loading signal: $err')),
      ),
      data: (signal) {
        if (signal == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Signal not found')),
          );
        }

        final isBuy = signal.direction == SignalDirection.buy;
        return Scaffold(
          appBar: AppBar(title: Text('${signal.symbol} Signal')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isBuy ? Colors.green.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isBuy ? 'BUY' : 'SELL',
                              style: TextStyle(
                                color: isBuy ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(signal.symbol, style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _DetailRow(label: 'Status', value: signal.status.name.toUpperCase()),
                      _DetailRow(label: 'Confidence', value: '${(signal.confidence * 100).toStringAsFixed(1)}%'),
                      _DetailRow(label: 'Confidence Label', value: signal.confidenceLabel.name.toUpperCase()),
                      _DetailRow(label: 'Confluence Count', value: '${signal.confluenceCount}'),
                      _DetailRow(label: 'Timeframes Aligned', value: '${signal.timeframesAligned}'),
                      _DetailRow(label: 'Risk/Reward Ratio', value: signal.riskRewardRatio.toStringAsFixed(2)),
                      _DetailRow(label: 'Pip Distance', value: '${signal.pipDistance.toStringAsFixed(1)} pips'),
                      const Divider(height: 24),
                      _DetailRow(label: 'Entry Price', value: signal.entryPrice.toStringAsFixed(5)),
                      _DetailRow(label: 'Stop Loss', value: signal.stopLoss.toStringAsFixed(5), valueColor: Colors.red),
                      _DetailRow(label: 'Take Profit', value: signal.takeProfit.toStringAsFixed(5), valueColor: Colors.green),
                      if (signal.actualProfit != null) ...[
                        const Divider(height: 24),
                        _DetailRow(label: 'Actual P&L', value: '${signal.actualProfit!.toStringAsFixed(1)} pips',
                            valueColor: signal.actualProfit! >= 0 ? Colors.green : Colors.red),
                      ],
                      if (signal.maxFavorableExcursion != null)
                        _DetailRow(label: 'Max Favorable Excursion', value: '${signal.maxFavorableExcursion!.toStringAsFixed(1)} pips'),
                      if (signal.maxAdverseExcursion != null)
                        _DetailRow(label: 'Max Adverse Excursion', value: '${signal.maxAdverseExcursion!.toStringAsFixed(1)} pips'),
                    ],
                  ),
                ),
              ),
              if (signal.indicatorsUsed.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Indicators Used', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: signal.indicatorsUsed.map((i) => Chip(
                    label: Text(i, style: const TextStyle(fontSize: 12)),
                    visualDensity: VisualDensity.compact,
                  )).toList(),
                ),
              ],
              if (signal.strategiesUsed.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Strategies Used', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: signal.strategiesUsed.map((s) => Chip(
                    label: Text(s, style: const TextStyle(fontSize: 12)),
                    visualDensity: VisualDensity.compact,
                  )).toList(),
                ),
              ],
              if (signal.aiNotes != null) ...[
                const SizedBox(height: 16),
                Text('AI Analysis', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Card(
                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.auto_awesome, size: 16, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Expanded(child: Text(signal.aiNotes!, style: theme.textTheme.bodyMedium)),
                      ],
                    ),
                  ),
                ),
              ],
              if (signal.newsAdjusted) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber, size: 16, color: Colors.orange[700]),
                      const SizedBox(width: 8),
                      Text('Signal was adjusted due to nearby high-impact news', style: TextStyle(color: Colors.orange[700], fontSize: 12)),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Text('Created: ${_formatDate(signal.createdAt)}', style: theme.textTheme.bodySmall),
              if (signal.closedAt != null)
                Text('Closed: ${_formatDate(signal.closedAt!)}', style: theme.textTheme.bodySmall),
              const SizedBox(height: 8),
              reportAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (report) {
                  if (report == null) return const SizedBox.shrink();
                  return Card(
                    color: Colors.red.withValues(alpha: 0.08),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.analytics, size: 18, color: Colors.red[700]),
                              const SizedBox(width: 8),
                              Text('Failure Analysis', style: theme.textTheme.titleMedium?.copyWith(color: Colors.red[700])),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text('Primary Cause:', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(report.description, style: theme.textTheme.bodyMedium),
                          const SizedBox(height: 12),
                          Text('Recommendations:', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          ...report.recommendedActions.entries.map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('• ', style: TextStyle(fontSize: 12)),
                                Expanded(
                                  child: Text(
                                    '${e.key}: ${e.value}',
                                    style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          )),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _DetailRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium),
          Text(value, style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600, color: valueColor)),
        ],
      ),
    );
  }
}
