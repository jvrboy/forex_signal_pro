import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/signal_repository.dart';
import '../../domain/models/signal_entity.dart';

final signalListProvider = FutureProvider<List<SignalEntity>>((ref) async {
  final repo = ref.watch(signalRepositoryProvider);
  return repo.getSignals();
});

final activeSignalsProvider = FutureProvider<List<SignalEntity>>((ref) async {
  final repo = ref.watch(signalRepositoryProvider);
  return repo.getActiveSignals();
});

class SignalListScreen extends ConsumerWidget {
  const SignalListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final signalsAsync = ref.watch(signalListProvider);
    final activeAsync = ref.watch(activeSignalsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Signals'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(signalListProvider);
              ref.invalidate(activeSignalsProvider);
            },
          ),
          IconButton(
            icon: const Icon(Icons.dashboard),
            onPressed: () => context.go('/dashboard'),
            tooltip: 'Signal Dashboard',
          ),
        ],
      ),
      body: signalsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text('Could not load signals', style: theme.textTheme.bodyLarge),
              TextButton(onPressed: () => ref.invalidate(signalListProvider), child: const Text('Retry')),
            ],
          ),
        ),
        data: (signals) {
          if (signals.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.timeline, size: 64, color: theme.disabledColor),
                  const SizedBox(height: 16),
                  Text('No signals yet', style: theme.textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  Text('Open a chart to generate signals', style: theme.textTheme.bodyMedium),
                ],
              ),
            );
          }

          final activeSignals = ref.watch(activeSignalsProvider).valueOrNull;
          final activeHeader = activeSignals != null && activeSignals.isNotEmpty
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text('Active (${activeSignals.length})', style: theme.textTheme.titleLarge),
                )
              : null;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (activeHeader != null) activeHeader,
              ...signals
                  .where((s) => s.status == SignalStatus.active)
                  .map((s) => _SignalCard(signal: s, onTap: () => context.go('/signal/${s.id}'))),
              if (signals.any((s) => s.status != SignalStatus.active)) ...[
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text('History (${signals.where((s) => s.status != SignalStatus.active).length})', style: theme.textTheme.titleLarge),
                ),
                ...signals
                    .where((s) => s.status != SignalStatus.active)
                    .toList()
                    .reversed
                    .map((s) => _SignalCard(signal: s, onTap: () => context.go('/signal/${s.id}'))),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _SignalCard extends ConsumerWidget {
  final SignalEntity signal;
  final VoidCallback? onTap;
  const _SignalCard({required this.signal, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isBuy = signal.direction == SignalDirection.buy;
    final isActive = signal.status == SignalStatus.active;

    Color statusColor;
    String statusLabel;
    switch (signal.status) {
      case SignalStatus.active:
        statusColor = theme.colorScheme.secondary;
        statusLabel = 'ACTIVE';
      case SignalStatus.tpHit:
        statusColor = Colors.green;
        statusLabel = 'TP HIT';
      case SignalStatus.slHit:
        statusColor = Colors.red;
        statusLabel = 'SL HIT';
      case SignalStatus.expired:
        statusColor = Colors.grey;
        statusLabel = 'EXPIRED';
      case SignalStatus.cancelled:
        statusColor = Colors.orange;
        statusLabel = 'CANCELLED';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isBuy ? Colors.green.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isBuy ? 'BUY' : 'SELL',
                      style: TextStyle(
                        color: isBuy ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(signal.symbol, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _StatItem(label: 'Confidence', value: '${(signal.confidence * 100).toStringAsFixed(0)}%'),
                  _StatItem(label: 'Confluence', value: '${signal.confluenceCount}'),
                  _StatItem(label: 'RR Ratio', value: signal.riskRewardRatio.toStringAsFixed(2)),
                  _StatItem(label: 'Timeframes', value: '${signal.timeframesAligned}'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _StatItem(label: 'Entry', value: signal.entryPrice.toStringAsFixed(5)),
                  _StatItem(label: 'SL', value: signal.stopLoss.toStringAsFixed(5)),
                  _StatItem(label: 'TP', value: signal.takeProfit.toStringAsFixed(5)),
                  if (signal.actualProfit != null)
                    _StatItem(
                      label: 'P&L',
                      value: '${signal.actualProfit!.toStringAsFixed(1)}p',
                      valueColor: signal.actualProfit! >= 0 ? Colors.green : Colors.red,
                    ),
                ],
              ),
              if (signal.aiNotes != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.auto_awesome, size: 14, color: theme.colorScheme.primary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(signal.aiNotes!, style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _StatItem({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.bodyMedium?.copyWith(fontSize: 11)),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(fontSize: 13, fontWeight: FontWeight.w600, color: valueColor),
          ),
        ],
      ),
    );
  }
}
