import 'package:flutter_test/flutter_test.dart';
import 'package:forex_signal_pro/features/charting/domain/candle.dart';
import 'package:forex_signal_pro/features/charting/domain/chart_state.dart';
import 'package:forex_signal_pro/features/charting/domain/indicator_calculator.dart';

void main() {
  group('Candle', () {
    test('isBullish when close >= open', () {
      expect(const Candle(open: 1.0, high: 1.1, low: 0.9, close: 1.05, epoch: 1).isBullish, isTrue);
      expect(const Candle(open: 1.0, high: 1.1, low: 0.9, close: 1.0, epoch: 1).isBullish, isTrue);
    });

    test('isBearish when close < open', () {
      expect(const Candle(open: 1.0, high: 1.1, low: 0.9, close: 0.95, epoch: 1).isBearish, isTrue);
    });

    test('range is high - low', () {
      final c = Candle(open: 1.0, high: 1.1, low: 0.9, close: 1.05, epoch: 1);
      expect(c.range, closeTo(0.2, 0.001));
    });

    test('body is absolute difference of close - open', () {
      final c1 = Candle(open: 1.0, high: 1.1, low: 0.9, close: 1.05, epoch: 1);
      final c2 = Candle(open: 1.05, high: 1.1, low: 0.9, close: 1.0, epoch: 1);
      expect(c1.body, closeTo(0.05, 0.001));
      expect(c2.body, closeTo(0.05, 0.001));
    });

    test('fromJson roundtrip', () {
      final json = {'open': 1.1, 'high': 1.12, 'low': 1.09, 'close': 1.11, 'epoch': 1000000, 'volume': 1500.0};
      final candle = Candle.fromJson(json);
      expect(candle.open, 1.1);
      expect(candle.high, 1.12);
      expect(candle.low, 1.09);
      expect(candle.close, 1.11);
      expect(candle.epoch, 1000000);
      expect(candle.volume, 1500.0);
    });

    test('fromTickSeries creates valid candle', () {
      final prices = [1.1, 1.12, 1.09, 1.11, 1.10];
      final candle = Candle.fromTickSeries(prices, 1000000, 60);
      expect(candle.open, 1.1);
      expect(candle.high, 1.12);
      expect(candle.low, 1.09);
      expect(candle.close, 1.10);
      expect(candle.epoch, 1000000);
    });

    test('dateTime converts epoch correctly', () {
      final candle = Candle(open: 1.0, high: 1.1, low: 0.9, close: 1.0, epoch: 1700000000);
      expect(candle.dateTime.year, 2023);
    });
  });

  group('Timeframe', () {
    test('label returns human-readable strings', () {
      expect(Timeframe.m1.label, '1m');
      expect(Timeframe.m5.label, '5m');
      expect(Timeframe.m15.label, '15m');
      expect(Timeframe.m30.label, '30m');
      expect(Timeframe.h1.label, '1H');
      expect(Timeframe.h2.label, '2H');
      expect(Timeframe.h4.label, '4H');
      expect(Timeframe.h8.label, '8H');
      expect(Timeframe.d1.label, '1D');
      expect(Timeframe.w1.label, '1W');
      expect(Timeframe.mn1.label, '1MN');
    });

    test('seconds returns correct values', () {
      expect(Timeframe.m1.seconds, 60);
      expect(Timeframe.h1.seconds, 3600);
      expect(Timeframe.d1.seconds, 86400);
      expect(Timeframe.w1.seconds, 604800);
    });

    test('all timeframes have positive seconds', () {
      for (final tf in Timeframe.values) {
        expect(tf.seconds, greaterThan(0));
        expect(tf.ticksPerCandle, greaterThan(0));
      }
    });

    test('ticksPerCandle matches seconds for basic timeframes', () {
      expect(Timeframe.m1.ticksPerCandle, 60);
      expect(Timeframe.h1.ticksPerCandle, 3600);
    });
  });

  group('ChartState', () {
    test('initial state has defaults', () {
      final state = ChartState();
      expect(state.candles, isEmpty);
      expect(state.timeframe, Timeframe.h1);
      expect(state.symbol, 'EURUSD');
      expect(state.visibleCandleCount, 50);
      expect(state.scrollOffset, 0);
      expect(state.indicators, isEmpty);
    });

    test('copyWith creates new state with overrides', () {
      final state = ChartState();
      final candles = [Candle(open: 1.0, high: 1.1, low: 0.9, close: 1.05, epoch: 1)];
      final modified = state.copyWith(
        candles: candles,
        timeframe: Timeframe.m5,
        symbol: 'GBPUSD',
        visibleCandleCount: 30,
      );
      expect(modified.candles.length, 1);
      expect(modified.timeframe, Timeframe.m5);
      expect(modified.symbol, 'GBPUSD');
      expect(modified.visibleCandleCount, 30);
      // originals unchanged
      expect(state.candles, isEmpty);
      expect(state.timeframe, Timeframe.h1);
    });

    test('visibleCandles returns correct subrange', () {
      final candles = List.generate(100, (i) => Candle(
        open: 1.0, high: 1.1, low: 0.9, close: 1.0, epoch: i,
      ));
      final state = ChartState(candles: candles, visibleCandleCount: 10);
      expect(state.visibleCandles.length, 10);
      expect(state.visibleCandles.first.epoch, 90);
      expect(state.visibleCandles.last.epoch, 99);

      final scrolled = state.copyWith(scrollOffset: 5);
      expect(scrolled.visibleCandles.length, 10);
      expect(scrolled.visibleCandles.first.epoch, 85);
    });

    test('visibleCandles handles edge cases', () {
      final candles = List.generate(5, (i) => Candle(
        open: 1.0, high: 1.1, low: 0.9, close: 1.0, epoch: i,
      ));
      // fewer candles than visibleCount
      final state = ChartState(candles: candles, visibleCandleCount: 50);
      expect(state.visibleCandles.length, 5);

      // scroll beyond start
      final overScrolled = state.copyWith(scrollOffset: 100);
      expect(overScrolled.visibleCandles, isEmpty);
    });
  });

  group('IndicatorConfig', () {
    test('default configs have correct values', () {
      expect(IndicatorConfig.sma14.period, 14);
      expect(IndicatorConfig.sma14.type, IndicatorType.sma);
      expect(IndicatorConfig.ema21.period, 21);
      expect(IndicatorConfig.bollinger.stdDev, 2.0);
      expect(IndicatorConfig.rsi14.period, 14);
      expect(IndicatorConfig.macdDefault.fastPeriod, 12);
      expect(IndicatorConfig.macdDefault.slowPeriod, 26);
      expect(IndicatorConfig.macdDefault.signalPeriod, 9);
    });

    test('toJson and fromJson roundtrip', () {
      final config = IndicatorConfig.macdDefault;
      final json = config.toJson();
      final restored = IndicatorConfig.fromJson(json);
      expect(restored.type, config.type);
      expect(restored.fastPeriod, config.fastPeriod);
      expect(restored.slowPeriod, config.slowPeriod);
      expect(restored.signalPeriod, config.signalPeriod);
    });

    test('fromJson handles missing optional fields', () {
      final json = {'type': 'sma', 'period': 20};
      final config = IndicatorConfig.fromJson(json);
      expect(config.type, IndicatorType.sma);
      expect(config.period, 20);
      expect(config.fastPeriod, isNull);
    });
  });

  group('IndicatorLabel', () {
    test('all indicators have non-empty labels', () {
      for (final type in IndicatorType.values) {
        expect(type.label.isNotEmpty, isTrue, reason: '${type.name} has empty label');
      }
    });
  });
}
