import 'package:flutter_test/flutter_test.dart';
import 'package:forex_signal_pro/features/signals/domain/neural_tracker/network.dart';
import 'package:forex_signal_pro/features/signals/domain/neural_tracker/failure_analyzer.dart';
import 'package:forex_signal_pro/features/signals/domain/neural_tracker/self_fix_engine.dart';
import 'package:forex_signal_pro/features/signals/domain/models/signal_entity.dart';

void main() {
  group('SelfFixEngine', () {
    late SignalScoringNN nn;
    late FailureAnalyzer analyzer;
    late List<SignalEntity> signals;

    setUp(() {
      nn = SignalScoringNN.defaultConfig();
      analyzer = FailureAnalyzer(nn: nn);
    });

    test('shouldSelfFix returns false with insufficient data', () async {
      final engine = SelfFixEngine(nn: nn, analyzer: analyzer, allSignals: []);
      final result = await engine.shouldSelfFix('EUR/USD');
      expect(result, isFalse);
    });

    test('shouldSelfFix returns false when failure rate below threshold', () async {
      signals = List.generate(15, (i) {
        return SignalEntity.create(
          symbol: 'EUR/USD',
          direction: SignalDirection.buy,
          entryPrice: 1.1000, stopLoss: 1.0980, takeProfit: 1.1040,
          confidence: 0.7, indicatorsUsed: [], strategiesUsed: [],
          confluenceCount: 3, timeframesAligned: 2,
        ).copyWith(
          status: i < 2 ? SignalStatus.slHit : SignalStatus.tpHit,
          closedAt: DateTime.now(),
        );
      });
      final engine = SelfFixEngine(
        nn: nn, analyzer: analyzer, allSignals: signals, failureThreshold: 0.3);
      final result = await engine.shouldSelfFix('EUR/USD');
      expect(result, isFalse);
    });

    test('shouldSelfFix returns true when failure rate exceeds threshold', () async {
      signals = List.generate(10, (i) {
        return SignalEntity.create(
          symbol: 'EUR/USD',
          direction: SignalDirection.buy,
          entryPrice: 1.1000, stopLoss: 1.0980, takeProfit: 1.1040,
          confidence: 0.7, indicatorsUsed: [], strategiesUsed: [],
          confluenceCount: 3, timeframesAligned: 2,
        ).copyWith(
          status: i < 4 ? SignalStatus.slHit : SignalStatus.tpHit,
          closedAt: DateTime.now(),
        );
      });
      final engine = SelfFixEngine(
        nn: nn, analyzer: analyzer, allSignals: signals, failureThreshold: 0.3);
      final result = await engine.shouldSelfFix('EUR/USD');
      expect(result, isTrue);
    });

    test('applySelfFix returns not applied when below threshold', () async {
      final engine = SelfFixEngine(nn: nn, analyzer: analyzer, allSignals: []);
      final result = await engine.applySelfFix('EUR/USD');
      expect(result['applied'], isFalse);
    });

    test('applySelfFix applies changes when failure rate high', () async {
      signals = List.generate(10, (i) {
        return SignalEntity.create(
          symbol: 'EUR/USD',
          direction: SignalDirection.buy,
          entryPrice: 1.1000, stopLoss: 1.0980, takeProfit: 1.1040,
          confidence: 0.7, indicatorsUsed: [], strategiesUsed: [],
          confluenceCount: 3, timeframesAligned: 2,
        ).copyWith(
          status: SignalStatus.slHit,
          closedAt: DateTime.now(),
        );
      });
      final engine = SelfFixEngine(
        nn: nn, analyzer: analyzer, allSignals: signals, failureThreshold: 0.3);
      final result = await engine.applySelfFix('EUR/USD');
      expect(result['applied'], isTrue);
      expect(result.containsKey('changes'), isTrue);
    });

    test('evaluateSignal returns value between 0 and 1', () {
      final engine = SelfFixEngine(nn: nn, analyzer: analyzer);
      final signal = SignalEntity.create(
        symbol: 'EUR/USD',
        direction: SignalDirection.buy,
        entryPrice: 1.1000, stopLoss: 1.0980, takeProfit: 1.1040,
        confidence: 0.7, indicatorsUsed: ['RSI', 'MACD'],
        strategiesUsed: ['TrendFollower'],
        confluenceCount: 5, timeframesAligned: 3,
      );
      final score = engine.evaluateSignal(signal);
      expect(score, greaterThanOrEqualTo(0.0));
      expect(score, lessThanOrEqualTo(1.0));
    });

    test('config is initially set with defaults', () {
      final engine = SelfFixEngine(nn: nn, analyzer: analyzer);
      expect(engine.config['atrMultiplier'], 1.5);
      expect(engine.config['minConfluence'], 3);
      expect(engine.config['requireTrendFilter'], isFalse);
    });

    test('trainOnRecentData does not throw with insufficient data', () async {
      final engine = SelfFixEngine(nn: nn, analyzer: analyzer);
      await engine.trainOnRecentData([]);
    });

    test('serialize returns config and fix history', () {
      final engine = SelfFixEngine(nn: nn, analyzer: analyzer);
      final serialized = engine.serialize();
      expect(serialized.containsKey('config'), isTrue);
      expect(serialized.containsKey('fixHistory'), isTrue);
    });

    test('fixHistory records applied fixes', () async {
      signals = List.generate(12, (i) {
        return SignalEntity.create(
          symbol: 'GBP/USD',
          direction: SignalDirection.sell,
          entryPrice: 1.2500, stopLoss: 1.2550, takeProfit: 1.2400,
          confidence: 0.65, indicatorsUsed: ['Bollinger'],
          strategiesUsed: ['Reversal'],
          confluenceCount: 4, timeframesAligned: 2,
        ).copyWith(
          status: i < 6 ? SignalStatus.slHit : SignalStatus.tpHit,
          closedAt: DateTime.now(),
        );
      });
      final engine = SelfFixEngine(
        nn: nn, analyzer: analyzer, allSignals: signals, failureThreshold: 0.3);
      await engine.applySelfFix('GBP/USD');
      expect(engine.fixHistory.isNotEmpty, isTrue);
    });
  });
}
