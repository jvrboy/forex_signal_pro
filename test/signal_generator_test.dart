import 'package:flutter_test/flutter_test.dart';
import 'package:forex_signal_pro/features/signals/domain/signal_generator.dart';
import 'package:forex_signal_pro/features/signals/domain/models/signal_entity.dart';

void main() {
  group('SignalGenerator', () {
    test('generates signal when confluence threshold met', () {
      final generator = SignalGenerator(
        currentPrice: 1.1000,
        atr: 0.0020,
        confluenceThreshold: 3,
      );

      final signal = generator.generateSignal(
        symbol: 'EUR/USD',
        direction: SignalDirection.buy,
        confluenceCount: 10,
        timeframesAligned: 4,
        indicatorsUsed: ['RSI', 'MACD', 'EMA'],
        strategiesUsed: ['Strategy1', 'Strategy2'],
      );

      expect(signal, isNotNull);
      expect(signal!.symbol, 'EUR/USD');
      expect(signal.direction, SignalDirection.buy);
      expect(signal.entryPrice, 1.1000);
      expect(signal.stopLoss, lessThan(signal.entryPrice));
      expect(signal.takeProfit, greaterThan(signal.entryPrice));
      expect(signal.confidence, greaterThan(0.5));
    });

    test('returns null when confluence threshold not met', () {
      final generator = SignalGenerator(
        currentPrice: 1.1000,
        atr: 0.0020,
        confluenceThreshold: 5,
      );

      final signal = generator.generateSignal(
        symbol: 'EUR/USD',
        direction: SignalDirection.buy,
        confluenceCount: 2,
        timeframesAligned: 1,
        indicatorsUsed: [],
        strategiesUsed: [],
      );

      expect(signal, isNull);
    });

    test('generates sell signal with correct SL/TP', () {
      final generator = SignalGenerator(
        currentPrice: 1.1000,
        atr: 0.0020,
      );

      final signal = generator.generateSignal(
        symbol: 'GBP/USD',
        direction: SignalDirection.sell,
        confluenceCount: 10,
        timeframesAligned: 4,
        indicatorsUsed: [],
        strategiesUsed: [],
      );

      expect(signal, isNotNull);
      expect(signal!.stopLoss, greaterThan(signal.entryPrice));
      expect(signal.takeProfit, lessThan(signal.entryPrice));
    });

    test('respects minConfidence filter', () {
      final generator = SignalGenerator(
        currentPrice: 1.1000,
        atr: 0.0020,
      );

      final signal = generator.generateSignal(
        symbol: 'EUR/USD',
        direction: SignalDirection.buy,
        confluenceCount: 1,
        timeframesAligned: 0,
        indicatorsUsed: [],
        strategiesUsed: [],
        minConfidence: 0.9,
      );

      expect(signal, isNull);
    });

    test('news adjustment reduces signal generation', () {
      final generator = SignalGenerator(
        currentPrice: 1.1000,
        atr: 0.0020,
      );

      final signalWithoutNews = generator.generateSignal(
        symbol: 'EUR/USD',
        direction: SignalDirection.buy,
        confluenceCount: 18,
        timeframesAligned: 5,
        indicatorsUsed: [],
        strategiesUsed: [],
        newsAdjusted: false,
      );

      final signalWithNews = generator.generateSignal(
        symbol: 'EUR/USD',
        direction: SignalDirection.buy,
        confluenceCount: 18,
        timeframesAligned: 5,
        indicatorsUsed: [],
        strategiesUsed: [],
        newsAdjusted: true,
      );

      expect(signalWithoutNews!.confidence, greaterThan(signalWithNews!.confidence));
    });
  });
}
