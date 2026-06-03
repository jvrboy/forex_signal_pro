import 'package:flutter_test/flutter_test.dart';
import 'package:forex_signal_pro/features/charting/domain/candle.dart';
import 'package:forex_signal_pro/features/charting/domain/indicator_calculator.dart';

List<Candle> _makeCandles(List<double> closes) {
  return closes.asMap().entries.map((e) => Candle(
    open: e.value, high: e.value + 0.001, low: e.value - 0.001,
    close: e.value, epoch: 1000000 + e.key,
  )).toList();
}

void main() {
  group('IndicatorCalculator', () {
    group('SMA', () {
      test('returns nulls for insufficient data', () {
        final candles = _makeCandles([1.0, 2.0, 3.0]);
        final result = IndicatorCalculator.sma(candles, 5);
        expect(result.every((v) => v == null), isTrue);
      });

      test('calculates correct SMA', () {
        final candles = _makeCandles([1.0, 2.0, 3.0, 4.0, 5.0]);
        final result = IndicatorCalculator.sma(candles, 3);
        expect(result[0], isNull);
        expect(result[1], isNull);
        expect(result[2], closeTo(2.0, 0.001));
        expect(result[3], closeTo(3.0, 0.001));
        expect(result[4], closeTo(4.0, 0.001));
      });
    });

    group('EMA', () {
      test('returns nulls for insufficient data', () {
        final candles = _makeCandles([1.0]);
        final result = IndicatorCalculator.ema(candles, 3);
        expect(result.every((v) => v == null), isTrue);
      });

      test('calculates EMA correctly', () {
        final candles = _makeCandles([1.0, 2.0, 3.0, 4.0, 5.0]);
        final result = IndicatorCalculator.ema(candles, 3);
        expect(result[0], isNull);
        expect(result[1], isNull);
        expect(result[2], closeTo(2.0, 0.5));
        expect(result[3], greaterThan(0));
        expect(result[4], greaterThan(0));
      });
    });

    group('RSI', () {
      test('returns nulls for insufficient data', () {
        final candles = _makeCandles([1.0, 2.0]);
        final result = IndicatorCalculator.rsi(candles, 14);
        expect(result.every((v) => v == null), isTrue);
      });

      test('calculates RSI between 0 and 100', () {
        final candles = _makeCandles(List.generate(30, (i) => 100.0 + i));
        final result = IndicatorCalculator.rsi(candles, 14);
        expect(result[14], greaterThan(0));
        expect(result[14], lessThan(100));
      });
    });

    group('Bollinger', () {
      test('returns nulls for insufficient data', () {
        final candles = _makeCandles([1.0, 2.0]);
        final result = IndicatorCalculator.bollinger(candles, 20, 2.0);
        expect(result.middle.every((v) => v == null), isTrue);
      });

      test('upper band above middle above lower', () {
        final candles = _makeCandles(List.generate(25, (i) => 50.0 + i * 0.1));
        final result = IndicatorCalculator.bollinger(candles, 20, 2.0);
        final last = result.upper.length - 1;
        expect(result.upper[last], greaterThan(result.middle[last]!));
        expect(result.middle[last]!, greaterThan(result.lower[last]!));
      });
    });

    group('MACD', () {
      test('returns calculated values for sufficient data', () {
        final candles = _makeCandles(List.generate(50, (i) => 100.0 + i * 0.5));
        final result = IndicatorCalculator.macd(candles, 12, 26, 9);
        expect(result.macd.length, 50);
        final lineCount = result.macd.where((v) => v != null).length;
        expect(lineCount, greaterThan(20));
      });
    });

    group('ATR', () {
      test('returns null for single candle', () {
        final candles = _makeCandles([1.0]);
        final result = IndicatorCalculator.atr(candles, 14);
        expect(result, hasLength(1));
        expect(result.first, isNull);
      });

      test('calculates ATR for sufficient data', () {
        final candles = _makeCandles(List.generate(20, (i) => 100.0 + i));
        final result = IndicatorCalculator.atr(candles, 14);
        expect(result[14], greaterThan(0));
      });
    });

    group('Stochastic', () {
      test('returns nulls for insufficient data', () {
        final candles = _makeCandles([1.0, 2.0]);
        final result = IndicatorCalculator.stochastic(candles, 14);
        expect(result.every((v) => v == null), isTrue);
      });

      test('calculates stochastic between 0 and 100', () {
        final candles = _makeCandles(List.generate(30, (i) => 50.0 + (i % 10) * 2.0));
        final result = IndicatorCalculator.stochastic(candles, 14);
        final last = result.where((v) => v != null);
        expect(last.every((v) => v! >= 0 && v <= 100), isTrue);
      });
    });

    group('Candle', () {
      test('isBullish when close >= open', () {
        expect(const Candle(open: 1.0, high: 1.1, low: 0.9, close: 1.05, epoch: 1).isBullish, isTrue);
        expect(const Candle(open: 1.0, high: 1.1, low: 0.9, close: 1.0, epoch: 1).isBullish, isTrue);
      });

      test('isBearish when close < open', () {
        expect(const Candle(open: 1.0, high: 1.1, low: 0.9, close: 0.95, epoch: 1).isBearish, isTrue);
      });

      test('riskRewardRatio and pipDistance on SignalEntity', () {
        // tested in neural_network_test
      });
    });

    group('Timeframe', () {
      test('label returns human-readable string', () {
        expect(Timeframe.m1.label, '1m');
        expect(Timeframe.h1.label, '1H');
        expect(Timeframe.d1.label, '1D');
        expect(Timeframe.w1.label, '1W');
      });

      test('seconds returns positive values', () {
        for (final tf in Timeframe.values) {
          expect(tf.seconds, greaterThan(0));
        }
      });
    });
  });
}
