import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:forex_signal_pro/features/signals/domain/neural_tracker/network.dart';
import 'package:forex_signal_pro/features/signals/domain/neural_tracker/failure_analyzer.dart';
import 'package:forex_signal_pro/features/signals/domain/models/signal_entity.dart';

void main() {
  group('FailureAnalyzer', () {
    late SignalScoringNN nn;
    late FailureAnalyzer analyzer;

    setUp(() {
      nn = SignalScoringNN.defaultConfig();
      analyzer = FailureAnalyzer(nn: nn);
    });

    test('analyze returns failure report for SL hit signal', () async {
      final signal = SignalEntity.create(
        symbol: 'EUR/USD',
        direction: SignalDirection.buy,
        entryPrice: 1.1000,
        stopLoss: 1.0980,
        takeProfit: 1.1040,
        confidence: 0.7,
        indicatorsUsed: ['RSI', 'MACD'],
        strategiesUsed: ['TrendFollower'],
        confluenceCount: 3,
        timeframesAligned: 2,
      ).copyWith(status: SignalStatus.slHit);

      final report = await analyzer.analyze(signal);
      expect(report.topCause, isA<FailureCause>());
      expect(report.description, isNotEmpty);
      expect(report.causes, isNotEmpty);
      expect(report.recommendedActions, isNotEmpty);
    });

    test('recommended actions contain actionable keys', () async {
      final signal = SignalEntity.create(
        symbol: 'EUR/USD',
        direction: SignalDirection.buy,
        entryPrice: 1.1000, stopLoss: 1.0980, takeProfit: 1.1040,
        confidence: 0.7, indicatorsUsed: [], strategiesUsed: [],
        confluenceCount: 3, timeframesAligned: 2,
      ).copyWith(status: SignalStatus.slHit);

      final report = await analyzer.analyze(signal);
      final actions = report.recommendedActions;
      expect(actions.containsKey('note'), isTrue);

      final hasValidKey = actions.keys.any((k) =>
        ['atrMultiplier', 'requireTrendFilter', 'entryZonePips',
         'newsFilter', 'regimeFilter', 'minConfluence',
         'maxAtrMultiplier', 'maxSpreadPips'].contains(k));
      expect(hasValidKey, isTrue);
    });
  });
}
