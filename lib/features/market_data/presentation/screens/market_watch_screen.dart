import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/market_data_provider.dart';
import '../../domain/models/symbol_info.dart';

class MarketWatchScreen extends ConsumerWidget {
  const MarketWatchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final symbolsAsync = ref.watch(forexSymbolsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Market Watch'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(activeSymbolsProvider),
          ),
        ],
      ),
      body: symbolsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text('Could not load symbols', style: theme.textTheme.bodyLarge),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.invalidate(activeSymbolsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (symbols) => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: symbols.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final symbol = symbols[index];
            return _SymbolTile(symbol: symbol);
          },
        ),
      ),
    );
  }
}

class _SymbolTile extends ConsumerWidget {
  final SymbolInfo symbol;
  const _SymbolTile({required this.symbol});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tickAsync = ref.watch(tickStreamProvider(symbol.symbol));

    return ListTile(
      title: Text(symbol.displayName, style: theme.textTheme.titleMedium),
      subtitle: Text(symbol.symbol, style: theme.textTheme.bodyMedium),
      trailing: tickAsync.when(
        data: (tick) => Text(
          tick.quote.toStringAsFixed(symbol.pipSize),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        loading: () => Text('---', style: theme.textTheme.bodyMedium),
        error: (_, __) => Text('--', style: theme.textTheme.bodyMedium),
      ),
      onTap: () {
        // Navigate to chart with this symbol
      },
    );
  }
}
