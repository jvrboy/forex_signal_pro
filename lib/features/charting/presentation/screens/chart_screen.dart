import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/candle.dart';
import '../../domain/chart_state.dart';
import '../widgets/candlestick_painter.dart';

final chartStateProvider = StateNotifierProvider<ChartStateNotifier, ChartState>((ref) {
  return ChartStateNotifier();
});

class ChartStateNotifier extends StateNotifier<ChartState> {
  ChartStateNotifier() : super(const ChartState());

  void setCandles(List<Candle> candles) => state = state.copyWith(candles: candles);
  void setTimeframe(Timeframe tf) => state = state.copyWith(timeframe: tf);
  void setSymbol(String s) => state = state.copyWith(symbol: s);
  void scroll(int offset) => state = state.copyWith(scrollOffset: offset);
  void zoomIn() => state = state.copyWith(visibleCandleCount: max(10, state.visibleCandleCount ~/ 1.5));
  void zoomOut() => state = state.copyWith(visibleCandleCount: min(200, state.visibleCandleCount * 1.5).toInt());
  void addIndicator(IndicatorConfig config) =>
      state = state.copyWith(indicators: [...state.indicators, config]);
  void removeIndicator(IndicatorType type) =>
      state = state.copyWith(indicators: state.indicators.where((i) => i.type != type).toList());
  void setCrosshair(double? price, int? index) =>
      state = state.copyWith(crosshairPrice: price, crosshairIndex: index);
}

class ChartScreen extends ConsumerStatefulWidget {
  const ChartScreen({super.key});

  @override
  ConsumerState<ChartScreen> createState() => _ChartScreenState();
}

class _ChartScreenState extends ConsumerState<ChartScreen> {
  String _selectedSymbol = 'EUR/USD';
  bool _showIndicators = false;
  final _indicators = <IndicatorConfig>[];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chartStateProvider.notifier).setSymbol(_selectedSymbol);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_selectedSymbol),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                ref.watch(chartStateProvider.select((s) => s.timeframe.label)),
                style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.add_chart), onPressed: () => _showIndicatorPicker(context), tooltip: 'Add Indicator'),
          IconButton(icon: const Icon(Icons.edit), onPressed: () => _showDrawingTools(context), tooltip: 'Drawing Tools'),
          IconButton(icon: const Icon(Icons.zoom_in), onPressed: () => ref.read(chartStateProvider.notifier).zoomIn(), tooltip: 'Zoom In'),
          IconButton(icon: const Icon(Icons.zoom_out), onPressed: () => ref.read(chartStateProvider.notifier).zoomOut(), tooltip: 'Zoom Out'),
        ],
      ),
      body: Column(
        children: [
          _TimeframeBar(),
          Expanded(child: _ChartArea(indicators: _indicators)),
          _SignalBar(theme: theme),
        ],
      ),
    );
  }

  void _showIndicatorPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: IndicatorType.values.where((t) => t != IndicatorType.none).map((indicator) {
          final active = _indicators.any((i) => i.type == indicator);
          return ListTile(
            leading: Icon(active ? Icons.check_box : Icons.check_box_outline_blank),
            title: Text(indicator.label),
            trailing: active ? IconButton(
              icon: const Icon(Icons.remove_circle, color: Colors.red),
              onPressed: () {
                setState(() => _indicators.removeWhere((i) => i.type == indicator));
                ref.read(chartStateProvider.notifier).removeIndicator(indicator);
                Navigator.pop(ctx);
              },
            ) : null,
            onTap: () {
              final config = _defaultConfig(indicator);
              setState(() => _indicators.add(config));
              ref.read(chartStateProvider.notifier).addIndicator(config);
              Navigator.pop(ctx);
            },
          );
        }).toList(),
      ),
    );
  }

  IndicatorConfig _defaultConfig(IndicatorType type) {
    switch (type) {
      case IndicatorType.sma: return IndicatorConfig.sma14;
      case IndicatorType.ema: return IndicatorConfig.ema21;
      case IndicatorType.bollinger: return IndicatorConfig.bollinger;
      case IndicatorType.rsi: return IndicatorConfig.rsi14;
      case IndicatorType.macd: return IndicatorConfig.macdDefault;
      case IndicatorType.atr: return IndicatorConfig.atr14;
      case IndicatorType.stochastic: return const IndicatorConfig(type: IndicatorType.stochastic);
      default: return IndicatorConfig(type: type);
    }
  }

  void _showDrawingTools(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Wrap(
        padding: const EdgeInsets.all(16),
        children: ['Trend Line', 'Fibonacci', 'Horizontal Line', 'Channel', 'Text', 'Arrow', 'Measure']
            .map((t) => Padding(
                  padding: const EdgeInsets.all(4),
                  child: ActionChip(label: Text(t, style: const TextStyle(fontSize: 12)), onPressed: () => Navigator.pop(ctx)),
                ))
            .toList(),
      ),
    );
  }
}

class _TimeframeBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTf = ref.watch(chartStateProvider.select((s) => s.timeframe));
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: Timeframe.values
            .map((tf) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: ChoiceChip(
                    label: Text(tf.label, style: const TextStyle(fontSize: 11)),
                    selected: tf == currentTf,
                    onSelected: (_) => ref.read(chartStateProvider.notifier).setTimeframe(tf),
                    visualDensity: VisualDensity.compact,
                  ),
                ))
            .toList(),
      ),
    );
  }
}

class _ChartArea extends ConsumerWidget {
  final List<IndicatorConfig> indicators;
  const _ChartArea({required this.indicators});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(chartStateProvider);

    if (state.candles.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.show_chart, size: 48, color: Colors.grey[600]),
            const SizedBox(height: 8),
            Text('No chart data', style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 4),
            Text('Connect to market data feed to see real-time charts', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ],
        ),
      );
    }

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        final notifier = ref.read(chartStateProvider.notifier);
        if (details.primaryVelocity! > 0) {
          notifier.scroll(max(0, state.scrollOffset - 10));
        } else {
          notifier.scroll(state.scrollOffset + 10);
        }
      },
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerTheme.color ?? Colors.grey[800]!),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CustomPaint(
            size: Size.infinite,
            painter: CandlestickPainter(
              candles: state.candles,
              indicators: state.indicators,
              visibleCount: state.visibleCandleCount,
              scrollOffset: state.scrollOffset,
              crosshairPrice: state.crosshairPrice,
              crosshairIndex: state.crosshairIndex,
            ),
          ),
        ),
      ),
    );
  }
}

class _SignalBar extends StatelessWidget {
  final ThemeData theme;
  const _SignalBar({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: theme.bottomNavigationBarTheme.backgroundColor,
        border: Border(top: BorderSide(color: theme.dividerTheme.color ?? Colors.grey[800]!)),
      ),
      child: Row(
        children: [
          Icon(Icons.notifications, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('No Active Signals', style: theme.textTheme.bodyMedium),
                Text('Generate signals from indicators', style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
              ],
            ),
          ),
          TextButton(onPressed: () {}, child: const Text('Generate')),
        ],
      ),
    );
  }
}
