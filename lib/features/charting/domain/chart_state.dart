import 'candle.dart';

enum IndicatorType {
  sma,
  ema,
  bollinger,
  rsi,
  macd,
  stochastic,
  ichimoku,
  atr,
  volume,
  none;

  String get label {
    switch (this) {
      case IndicatorType.sma: return 'SMA';
      case IndicatorType.ema: return 'EMA';
      case IndicatorType.bollinger: return 'Bollinger Bands';
      case IndicatorType.rsi: return 'RSI';
      case IndicatorType.macd: return 'MACD';
      case IndicatorType.stochastic: return 'Stochastic';
      case IndicatorType.ichimoku: return 'Ichimoku';
      case IndicatorType.atr: return 'ATR';
      case IndicatorType.volume: return 'Volume';
      case IndicatorType.none: return 'None';
    }
  }
}

class IndicatorConfig {
  final IndicatorType type;
  final int period;
  final int? fastPeriod;
  final int? slowPeriod;
  final int? signalPeriod;
  final double? stdDev;
  final bool visible;
  final String? color;

  const IndicatorConfig({
    required this.type,
    this.period = 14,
    this.fastPeriod,
    this.slowPeriod,
    this.signalPeriod,
    this.stdDev,
    this.visible = true,
    this.color,
  });

  static const sma14 = IndicatorConfig(type: IndicatorType.sma, period: 14);
  static const ema21 = IndicatorConfig(type: IndicatorType.ema, period: 21);
  static const ema50 = IndicatorConfig(type: IndicatorType.ema, period: 50);
  static const bollinger = IndicatorConfig(
    type: IndicatorType.bollinger, period: 20, stdDev: 2.0);
  static const rsi14 = IndicatorConfig(type: IndicatorType.rsi, period: 14);
  static const macdDefault = IndicatorConfig(
    type: IndicatorType.macd, fastPeriod: 12, slowPeriod: 26, signalPeriod: 9);
  static const atr14 = IndicatorConfig(type: IndicatorType.atr, period: 14);

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'period': period,
    'fastPeriod': fastPeriod,
    'slowPeriod': slowPeriod,
    'signalPeriod': signalPeriod,
    'stdDev': stdDev,
    'visible': visible,
    'color': color,
  };

  factory IndicatorConfig.fromJson(Map<String, dynamic> json) => IndicatorConfig(
    type: IndicatorType.values.byName(json['type'] as String),
    period: json['period'] as int? ?? 14,
    fastPeriod: json['fastPeriod'] as int?,
    slowPeriod: json['slowPeriod'] as int?,
    signalPeriod: json['signalPeriod'] as int?,
    stdDev: json['stdDev'] != null ? (json['stdDev'] as num).toDouble() : null,
    visible: json['visible'] as bool? ?? true,
    color: json['color'] as String?,
  );
}

class DrawingTool {
  final String id;
  final String type;
  final List<({int candleIndex, double price})> points;
  final String color;
  final double lineWidth;

  const DrawingTool({
    required this.id,
    required this.type,
    required this.points,
    this.color = '#FFFFFF',
    this.lineWidth = 1.0,
  });
}

class ChartState {
  final List<Candle> candles;
  final Timeframe timeframe;
  final String symbol;
  final List<IndicatorConfig> indicators;
  final List<DrawingTool> drawings;
  final int visibleCandleCount;
  final int scrollOffset;
  final double? crosshairPrice;
  final int? crosshairIndex;

  const ChartState({
    this.candles = const [],
    this.timeframe = Timeframe.h1,
    this.symbol = 'EURUSD',
    this.indicators = const [],
    this.drawings = const [],
    this.visibleCandleCount = 50,
    this.scrollOffset = 0,
    this.crosshairPrice,
    this.crosshairIndex,
  });

  ChartState copyWith({
    List<Candle>? candles,
    Timeframe? timeframe,
    String? symbol,
    List<IndicatorConfig>? indicators,
    List<DrawingTool>? drawings,
    int? visibleCandleCount,
    int? scrollOffset,
    double? crosshairPrice,
    int? crosshairIndex,
  }) {
    return ChartState(
      candles: candles ?? this.candles,
      timeframe: timeframe ?? this.timeframe,
      symbol: symbol ?? this.symbol,
      indicators: indicators ?? this.indicators,
      drawings: drawings ?? this.drawings,
      visibleCandleCount: visibleCandleCount ?? this.visibleCandleCount,
      scrollOffset: scrollOffset ?? this.scrollOffset,
      crosshairPrice: crosshairPrice ?? this.crosshairPrice,
      crosshairIndex: crosshairIndex ?? this.crosshairIndex,
    );
  }

  List<Candle> get visibleCandles {
    final start = candles.length - visibleCandleCount - scrollOffset;
    final end = candles.length - scrollOffset;
    if (start < 0) return candles.sublist(0, end);
    if (start >= candles.length) return [];
    return candles.sublist(start, end);
  }
}
