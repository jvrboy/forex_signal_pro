import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/deriv_socket_service.dart';

final _tokenProvider = StateProvider<String?>((ref) => null);
final _authLoadingProvider = StateProvider<bool>((ref) => false);

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final token = ref.watch(_tokenProvider);
    final isLoading = ref.watch(_authLoadingProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.trending_up, size: 80, color: theme.colorScheme.primary),
                const SizedBox(height: 24),
                Text('Forex Signal Pro', style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('AI-Powered Trading Signals', style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
                const SizedBox(height: 48),

                // API Token Input
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Deriv API Token',
                    hintText: 'Paste your API token here',
                    prefixIcon: const Icon(Icons.vpn_key),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    suffixIcon: token != null && token.isNotEmpty
                        ? IconButton(icon: const Icon(Icons.clear), onPressed: () {
                            ref.read(_tokenProvider.notifier).state = null;
                          })
                        : null,
                  ),
                  obscureText: true,
                  onChanged: (value) => ref.read(_tokenProvider.notifier).state = value.trim(),
                ),
                const SizedBox(height: 16),

                // Connect Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: isLoading || token == null || token.isEmpty
                        ? null
                        : () => _connect(context, ref, token),
                    icon: isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.link),
                    label: Text(isLoading ? 'Connecting...' : 'Connect to Deriv'),
                  ),
                ),
                const SizedBox(height: 32),

                // How to get token
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('How to get your API token:',
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      _stepLabel('1. Log in to your Deriv account'),
                      _stepLabel('2. Go to Settings > API Token'),
                      _stepLabel('3. Create a new token with "Read & Trade" permissions'),
                      _stepLabel('4. Copy and paste the token above'),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                // Risk disclaimer
                Text(
                  'RISK DISCLAIMER: Trading forex carries significant risk. '
                  'Past performance does not guarantee future results. '
                  'This app provides signals, not financial advice.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _stepLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  Future<void> _connect(BuildContext context, WidgetRef ref, String token) async {
    ref.read(_authLoadingProvider.notifier).state = true;
    try {
      final socketService = ref.read(derivSocketProvider);
      final storage = const FlutterSecureStorage();
      await storage.write(key: 'deriv_api_token', value: token);

      await socketService.connect(authToken: token);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connected to Deriv successfully'), backgroundColor: Colors.green),
        );
        context.go('/market');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connection failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      ref.read(_authLoadingProvider.notifier).state = false;
    }
  }
}
