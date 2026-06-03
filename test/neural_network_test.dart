import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:forex_signal_pro/features/signals/domain/neural_tracker/network.dart';
import 'package:forex_signal_pro/features/signals/domain/neural_tracker/feature_extractor.dart';
import 'package:forex_signal_pro/features/signals/domain/models/signal_entity.dart';

void main() {
  group('SignalScoringNN', () {
    late SignalScoringNN nn;

    setUp(() {
      nn = SignalScoringNN.defaultConfig();
    });

    test('predict returns value between 0 and 1', () {
      final features = Float64List(20);
      for (int i = 0; i < 20; i++) {
        features[i] = 0.5;
      }

      final result = nn.predict(features);
      expect(result, greaterThanOrEqualTo(0.0));
      expect(result, lessThanOrEqualTo(1.0));
    });

    test('predict with all zeros returns some value', () {
      final features = Float64List(20);
      final result = nn.predict(features);
      expect(result, isA<double>());
    });

    test('train reduces loss over epochs', () {
      final examples = List.generate(20, (i) {
        final features = Float64List(20);
        final label = i < 10 ? 1.0 : 0.0;
        for (int j = 0; j < 20; j++) {
          features[j] = (i + j) % 10 / 10.0;
        }
        return TrainingExample(features: features, label: label);
      });

      final loss1 = nn.train(examples, epochs: 5);
      final loss2 = nn.train(examples, epochs: 10);
      expect(loss2, lessThanOrEqualTo(loss1));
    });

    test('serialize and deserialize roundtrip', () {
      final data = nn.serialize();
      final restored = SignalScoringNN.deserialize(data);

      final features = Float64List(20);
      for (int i = 0; i < 20; i++) {
        features[i] = 0.3;
      }

      expect(nn.predict(features), closeTo(restored.predict(features), 0.001));
    });

    test('feature importance returns non-negative values summing to 1', () {
      final features = Float64List(20);
      for (int i = 0; i < 20; i++) {
        features[i] = i / 20.0;
      }

      final importances = nn.featureImportance(baselineFeatures: features, samples: 50);
      expect(importances.length, 20);
      expect(importances.every((v) => v >= 0), isTrue);

      final sum = importances.fold(0.0, (a, b) => a + b);
      expect(sum, closeTo(1.0, 0.1));
    });
  });

  group('FeatureExtractor', () {
    test('fromSignal creates normalized features', () {
      final signal = SignalEntity.create(
        symbol: 'EUR/USD',
        direction: SignalDirection.buy,
        entryPrice: 1.1050,
        stopLoss: 1.1000,
        takeProfit: 1.1150,
        confidence: 0.75,
        indicatorsUsed: ['RSI', 'MACD', 'EMA'],
        strategiesUsed: ['TrendFollower', 'Breakout'],
        confluenceCount: 5,
        timeframesAligned: 3,
      );

      final features = FeatureExtractor.fromSignal(signal);
      final normalized = features.toNormalizedList();

      expect(normalized.length, 20);
      expect(normalized.every((v) => v >= 0 && v <= 1), isTrue);
    });

    test('feature names list has 20 entries', () {
      expect(FeatureExtractor.featureNames.length, 20);
    });
  });

  group('SignalEntity', () {
    test('create generates id and timestamp', () {
      final signal = SignalEntity.create(
        symbol: 'GBP/USD',
        direction: SignalDirection.sell,
        entryPrice: 1.2500,
        stopLoss: 1.2550,
        takeProfit: 1.2400,
        confidence: 0.80,
        indicatorsUsed: ['Bollinger', 'RSI'],
        strategiesUsed: ['Reversal'],
        confluenceCount: 3,
        timeframesAligned: 2,
      );

      expect(signal.id, isNotEmpty);
      expect(signal.status, SignalStatus.active);
      expect(signal.riskRewardRatio, closeTo(2.0, 0.01));
    });

    test('confidence label mapping', () {
      final low = SignalEntity.create(
        symbol: 'EUR/USD',
        direction: SignalDirection.buy,
        entryPrice: 1.10, stopLoss: 1.09, takeProfit: 1.12,
        confidence: 0.4, indicatorsUsed: [], strategiesUsed: [],
        confluenceCount: 1, timeframesAligned: 1,
      );
      expect(low.confidenceLabel, SignalConfidence.low);

      final high = SignalEntity.create(
        symbol: 'EUR/USD',
        direction: SignalDirection.buy,
        entryPrice: 1.10, stopLoss: 1.09, takeProfit: 1.12,
        confidence: 0.75, indicatorsUsed: [], strategiesUsed: [],
        confluenceCount: 5, timeframesAligned: 3,
      );
      expect(high.confidenceLabel, SignalConfidence.high);
    });
  });
}
