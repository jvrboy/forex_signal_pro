import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/llm_service.dart';

final llmServiceProvider = Provider<LlmService>((ref) {
  final service = LlmService();
  ref.onDispose(() => service.dispose());
  return service;
});

class _ChatMessageData {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  _ChatMessageData({required this.text, required this.isUser, DateTime? timestamp})
      : timestamp = timestamp ?? DateTime.now();
}

final _chatHistoryProvider = StateProvider<List<_ChatMessageData>>((ref) => []);

class AiChatScreen extends ConsumerStatefulWidget {
  const AiChatScreen({super.key});

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _isLoading = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final chatHistory = ref.read(_chatHistoryProvider.notifier);
    chatHistory.state = [...chatHistory.state, _ChatMessageData(text: text, isUser: true)];
    _controller.clear();
    setState(() => _isLoading = true);
    _scrollToBottom();

    final llm = ref.read(llmServiceProvider);
    String response;
    if (llm.status != LlmStatus.ready) {
      final loaded = await llm.loadModel('');
      if (!loaded) {
        response = '⚠️ Model not available. The AI agent requires a local .gguf model file to operate.\n\n'
            '**To set up:**\n1. Download a GGUF model (e.g., Llama, Mistral, Phi)\n'
            '2. Place it in `assets/gguf_models/`\n'
            '3. Go to Settings → AI Agent → LLM Model to configure\n\n'
            'No model is loaded — configure one to enable AI analysis.';
      } else {
        response = await llm.generate(text);
      }
    } else {
      response = await llm.generate(text);
    }

    chatHistory.state = [...chatHistory.state, _ChatMessageData(text: response, isUser: false)];
    setState(() => _isLoading = false);
    _scrollToBottom();
  }

  void _clearChat() {
    ref.read(_chatHistoryProvider.notifier).state = [];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final llm = ref.watch(llmServiceProvider);
    final messages = ref.watch(_chatHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            const Text('AI Agent'),
          ],
        ),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              color: _statusColor(llm.status).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, size: 8, color: _statusColor(llm.status)),
                const SizedBox(width: 4),
                Text(_statusLabel(llm.status),
                    style: TextStyle(fontSize: 11, color: _statusColor(llm.status))),
              ],
            ),
          ),
          if (messages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep, size: 20),
              onPressed: _clearChat,
              tooltip: 'Clear chat',
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            color: theme.colorScheme.primary.withValues(alpha: 0.04),
            child: Row(
              children: [
                Icon(Icons.lightbulb, size: 14, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Analyze markets, review signals, get strategy advice, or debug failed trades.',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: messages.isEmpty
                ? _buildEmptyState(theme, llm)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == messages.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                        );
                      }
                      final msg = messages[index];
                      return _MessageBubble(
                        text: msg.text,
                        isUser: msg.isUser,
                        timestamp: msg.timestamp,
                        isDark: theme.brightness == Brightness.dark,
                      );
                    },
                  ),
          ),
          _buildInputBar(theme),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, LlmService llm) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat, size: 48, color: theme.disabledColor),
            const SizedBox(height: 16),
            Text('How can I help you trade?', style: theme.textTheme.titleLarge),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _SuggestionChip(
                  label: 'Analyze EUR/USD',
                  icon: Icons.trending_up,
                  onTap: () => _sendMessage('Analyze EUR/USD for current market conditions, including trend direction, key support/resistance levels, and potential entry points.'),
                ),
                _SuggestionChip(
                  label: 'Why did my signal fail?',
                  icon: Icons.analytics,
                  onTap: () => _sendMessage('What are the most common reasons forex signals hit stop loss? Analyze possible failure causes.'),
                ),
                _SuggestionChip(
                  label: 'Best strategy today',
                  icon: Icons.psychology,
                  onTap: () => _sendMessage('What is the best trading strategy for current market conditions? Consider trend, volatility, and upcoming news.'),
                ),
                _SuggestionChip(
                  label: 'Explain RSI divergence',
                  icon: Icons.science,
                  onTap: () => _sendMessage('Explain RSI divergence in detail - how to identify bullish and bearish divergence, and how to trade it.'),
                ),
                _SuggestionChip(
                  label: 'Risk management tips',
                  icon: Icons.shield,
                  onTap: () => _sendMessage('What are the best risk management practices for forex trading? Include position sizing, stop loss placement, and risk-reward ratios.'),
                ),
                _SuggestionChip(
                  label: 'News trading guide',
                  icon: Icons.calendar_month,
                  onTap: () => _sendMessage('How should I adjust my trading around high-impact news events? What strategies work best for news trading?'),
                ),
              ],
            ),
            if (llm.status != LlmStatus.ready) ...[
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange[700], size: 24),
                    const SizedBox(height: 8),
                    Text('AI model not loaded',
                        style: theme.textTheme.titleSmall?.copyWith(color: Colors.orange[700])),
                    const SizedBox(height: 4),
                    Text('Configure a GGUF model in Settings for full AI capabilities.',
                        style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        border: Border(top: BorderSide(color: theme.dividerTheme.color ?? Colors.grey[800]!)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: 'Ask the AI agent...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: _isLoading ? null : _sendMessage,
                minLines: 1,
                maxLines: 4,
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: _isLoading ? Colors.grey : theme.colorScheme.primary,
              child: IconButton(
                icon: Icon(_isLoading ? Icons.stop : Icons.send, size: 18),
                color: Colors.white,
                onPressed: _isLoading ? () => setState(() => _isLoading = false) : () => _sendMessage(_controller.text),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(LlmStatus status) {
    switch (status) {
      case LlmStatus.ready: return Colors.green;
      case LlmStatus.loading: return Colors.orange;
      case LlmStatus.error: return Colors.red;
      case LlmStatus.unloaded: return Colors.grey;
    }
  }

  String _statusLabel(LlmStatus status) {
    switch (status) {
      case LlmStatus.ready: return 'Ready';
      case LlmStatus.loading: return 'Loading';
      case LlmStatus.error: return 'Error';
      case LlmStatus.unloaded: return 'Offline';
    }
  }
}

class _MessageBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isDark;
  const _MessageBubble({
    required this.text,
    required this.isUser,
    required this.timestamp,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.2),
              child: Icon(Icons.auto_awesome, size: 14, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser
                    ? theme.colorScheme.primary.withValues(alpha: 0.15)
                    : theme.cardTheme.color,
                borderRadius: BorderRadius.circular(16).copyWith(
                  bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(16),
                  bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(4),
                ),
                border: Border.all(color: (theme.dividerTheme.color ?? Colors.grey[800]!).withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFormattedText(text, theme, context),
                  const SizedBox(height: 4),
                  Text(
                    '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildFormattedText(String text, ThemeData theme, BuildContext context) {
    final spans = <TextSpan>[];
    final lines = text.split('\n');

    for (final line in lines) {
      if (line.startsWith('**') && line.endsWith('**')) {
        spans.add(TextSpan(
          text: '${line.substring(2, line.length - 2)}\n',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: theme.colorScheme.primary),
        ));
      } else if (line.startsWith('### ')) {
        spans.add(TextSpan(
          text: '${line.substring(4)}\n',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ));
      } else if (line.startsWith('## ')) {
        spans.add(TextSpan(
          text: '${line.substring(3)}\n',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ));
      } else if (line.startsWith('- ') || line.startsWith('* ')) {
        spans.add(TextSpan(
          text: '• ${line.substring(2)}\n',
          style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withValues(alpha: 0.85)),
        ));
      } else if (line.startsWith('  - ') || line.startsWith('  * ')) {
        spans.add(TextSpan(
          text: '  ◦ ${line.substring(4)}\n',
          style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.75)),
        ));
      } else if (line.startsWith('⚠️') || line.startsWith('✅') || line.startsWith('❌')) {
        spans.add(TextSpan(
          text: '$line\n',
          style: TextStyle(fontSize: 13),
        ));
      } else if (line.contains('http') || line.contains('//')) {
        spans.add(TextSpan(
          text: '$line\n',
          style: TextStyle(color: Colors.blue, fontSize: 13),
        ));
      } else {
        spans.add(TextSpan(
          text: '$line\n',
          style: TextStyle(fontSize: 13),
        ));
      }
    }

    return RichText(
      text: TextSpan(children: spans, style: DefaultTextStyle.of(context).style),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  const _SuggestionChip({required this.label, this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: icon != null ? Icon(icon, size: 14) : null,
      label: Text(label, style: const TextStyle(fontSize: 12)),
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
    );
  }
}
