import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/deriv_socket_service.dart';
import '../../../../core/network/messages/trade_models.dart';

final accountBalanceProvider = StreamProvider<AccountBalance?>((ref) {
  final service = ref.watch(derivSocketProvider);
  final controller = StreamController<AccountBalance?>();
  final sub = service.rawMessages.listen((msg) {
    if (msg['msg_type'] == 'balance' && msg['balance'] != null) {
      controller.add(AccountBalance.fromJson(msg['balance'] as Map<String, dynamic>));
    }
  });
  ref.onDispose(() {
    sub.cancel();
    controller.close();
  });
  return controller.stream;
});

class PortfolioScreen extends ConsumerStatefulWidget {
  const PortfolioScreen({super.key});

  @override
  ConsumerState<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends ConsumerState<PortfolioScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final balanceAsync = ref.watch(accountBalanceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Portfolio')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          balanceAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => _buildNoConnectionCard(theme),
            data: (balance) => balance != null
                ? _buildBalanceCard(balance, theme)
                : _buildNoConnectionCard(theme),
          ),
          const SizedBox(height: 24),
          Text('Open Positions', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          _buildEmptyState(theme, 'No open positions', 'Connect your Deriv account to trade'),
          const SizedBox(height: 24),
          Text('Recent Trades', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          _buildEmptyState(theme, 'No trade history', 'Your closed trades will appear here'),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(AccountBalance balance, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text('Account Balance', style: theme.textTheme.bodyMedium),
            const SizedBox(height: 8),
            Text('${balance.currency} ${balance.balance.toStringAsFixed(2)}',
                style: theme.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold)),
            if (balance.profitLoss != null) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(balance.profitLoss! >= 0 ? Icons.trending_up : Icons.trending_down,
                      size: 16, color: balance.profitLoss! >= 0 ? Colors.green : Colors.red),
                  const SizedBox(width: 4),
                  Text('${balance.profitLoss! >= 0 ? '+' : ''}${balance.profitLoss!.toStringAsFixed(2)} ${balance.currency}',
                      style: TextStyle(color: balance.profitLoss! >= 0 ? Colors.green : Colors.red)),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Virtual: ${balance.isVirtual ? 'Yes' : 'No'}', style: theme.textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoConnectionCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.cloud_off, size: 40, color: theme.disabledColor),
            const SizedBox(height: 12),
            Text('Not Connected', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('Connect to Deriv via the Login screen to see your account balance.',
                style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, String title, String subtitle) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.inbox, size: 48, color: theme.disabledColor),
              const SizedBox(height: 8),
              Text(title, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 4),
              Text(subtitle, style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
