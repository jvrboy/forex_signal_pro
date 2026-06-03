import 'package:flutter_test/flutter_test.dart';
import 'package:forex_signal_pro/features/signals/domain/models/signal_entity.dart';
import 'package:forex_signal_pro/features/signals/data/signal_repository.dart';
import 'package:forex_signal_pro/core/persistence/json_persistence.dart';
import 'package:forex_signal_pro/core/persistence/signal_json_adapter.dart';

void main() {
  group('PersistentSignalRepository', () {
    late JsonPersistence store;
    late CollectionPersistence<SignalEntity> collection;
    late PersistentSignalRepository repo;

    setUp(() {
      store = JsonPersistence(fileName: 'test_signals_${DateTime.now().millisecondsSinceEpoch}.json');
      collection = CollectionPersistence<SignalEntity>(
        store: store,
        collectionKey: 'signals',
        fromJson: _signalFromJson,
        toJson: _signalToJson,
      );
      repo = PersistentSignalRepository(collection: collection);
    });

    tearDown(() async {
      await store.clear();
    });

    test('getSignals returns empty list initially', () async {
      final signals = await repo.getSignals();
      expect(signals, isEmpty);
    });

    test('addSignal and getSignals roundtrip', () async {
      final signal = SignalEntity.create(
        symbol: 'EUR/USD',
        direction: SignalDirection.buy,
        entryPrice: 1.1000, stopLoss: 1.0980, takeProfit: 1.1040,
        confidence: 0.75, indicatorsUsed: ['RSI', 'MACD'],
        strategiesUsed: ['TrendFollower'], confluenceCount: 5, timeframesAligned: 3,
      );
      await repo.addSignal(signal);
      final signals = await repo.getSignals();
      expect(signals.length, 1);
      expect(signals.first.id, signal.id);
      expect(signals.first.symbol, 'EUR/USD');
    });

    test('getActiveSignals returns only active', () async {
      final active = SignalEntity.create(
        symbol: 'EUR/USD', direction: SignalDirection.buy,
        entryPrice: 1.10, stopLoss: 1.09, takeProfit: 1.12,
        confidence: 0.7, indicatorsUsed: [], strategiesUsed: [],
        confluenceCount: 3, timeframesAligned: 2,
      );
      final closed = active.copyWith(status: SignalStatus.tpHit, closedAt: DateTime.now());
      await repo.addSignal(active);
      await repo.addSignal(closed);
      final activeSignals = await repo.getActiveSignals();
      expect(activeSignals.length, 1);
      expect(activeSignals.first.status, SignalStatus.active);
    });

    test('updateSignal persists changes', () async {
      final signal = SignalEntity.create(
        symbol: 'GBP/USD', direction: SignalDirection.sell,
        entryPrice: 1.25, stopLoss: 1.2550, takeProfit: 1.2400,
        confidence: 0.8, indicatorsUsed: [], strategiesUsed: [],
        confluenceCount: 3, timeframesAligned: 2,
      );
      await repo.addSignal(signal);
      final updated = signal.copyWith(status: SignalStatus.tpHit, actualProfit: 50.0);
      await repo.updateSignal(updated);
      final fetched = await repo.getSignal(signal.id);
      expect(fetched!.status, SignalStatus.tpHit);
      expect(fetched.actualProfit, 50.0);
    });

    test('getWinRate returns correct ratio', () async {
      for (var i = 0; i < 5; i++) {
        final win = SignalEntity.create(
          symbol: 'EUR/USD', direction: SignalDirection.buy,
          entryPrice: 1.10, stopLoss: 1.09, takeProfit: 1.12,
          confidence: 0.7, indicatorsUsed: [], strategiesUsed: [],
          confluenceCount: 3, timeframesAligned: 2,
        ).copyWith(status: SignalStatus.tpHit, closedAt: DateTime.now());
        await repo.addSignal(win);
      }
      for (var i = 0; i < 5; i++) {
        final loss = SignalEntity.create(
          symbol: 'EUR/USD', direction: SignalDirection.buy,
          entryPrice: 1.10, stopLoss: 1.09, takeProfit: 1.12,
          confidence: 0.7, indicatorsUsed: [], strategiesUsed: [],
          confluenceCount: 3, timeframesAligned: 2,
        ).copyWith(status: SignalStatus.slHit, closedAt: DateTime.now());
        await repo.addSignal(loss);
      }
      final winRate = await repo.getWinRate('EUR/USD');
      expect(winRate, closeTo(0.5, 0.01));
    });

    test('getSignalsBySymbol filters correctly', () async {
      final eur = SignalEntity.create(symbol: 'EUR/USD', direction: SignalDirection.buy,
        entryPrice: 1.10, stopLoss: 1.09, takeProfit: 1.12,
        confidence: 0.7, indicatorsUsed: [], strategiesUsed: [],
        confluenceCount: 3, timeframesAligned: 2);
      final gbp = SignalEntity.create(symbol: 'GBP/USD', direction: SignalDirection.sell,
        entryPrice: 1.25, stopLoss: 1.2550, takeProfit: 1.2400,
        confidence: 0.7, indicatorsUsed: [], strategiesUsed: [],
        confluenceCount: 3, timeframesAligned: 2);
      await repo.addSignal(eur);
      await repo.addSignal(gbp);
      final eurSignals = await repo.getSignalsBySymbol('EUR/USD');
      expect(eurSignals.length, 1);
      expect(eurSignals.first.symbol, 'EUR/USD');
    });

    test('clearSignals removes all data', () async {
      final signal = SignalEntity.create(symbol: 'EUR/USD', direction: SignalDirection.buy,
        entryPrice: 1.10, stopLoss: 1.09, takeProfit: 1.12,
        confidence: 0.7, indicatorsUsed: [], strategiesUsed: [],
        confluenceCount: 3, timeframesAligned: 2);
      await repo.addSignal(signal);
      await repo.clearSignals();
      final signals = await repo.getSignals();
      expect(signals, isEmpty);
    });

    test('getRecentSignals returns most recent first', () async {
      for (var i = 0; i < 5; i++) {
        await repo.addSignal(SignalEntity.create(
          symbol: 'EUR/USD', direction: SignalDirection.buy,
          entryPrice: 1.10, stopLoss: 1.09, takeProfit: 1.12,
          confidence: 0.7, indicatorsUsed: [], strategiesUsed: [],
          confluenceCount: 3, timeframesAligned: 2,
        ));
        await Future.delayed(const Duration(milliseconds: 1));
      }
      final recent = await repo.getRecentSignals(3);
      expect(recent.length, 3);
      expect(recent[0].createdAt.isAfter(recent[1].createdAt), isTrue);
    });
  });
}

Map<String, dynamic> _signalToJson(SignalEntity s) {
  return {
    'id': s.id, 'symbol': s.symbol, 'direction': s.direction.name,
    'entryPrice': s.entryPrice, 'stopLoss': s.stopLoss, 'takeProfit': s.takeProfit,
    'confidence': s.confidence, 'confidenceLabel': s.confidenceLabel.name,
    'status': s.status.name, 'indicatorsUsed': s.indicatorsUsed,
    'strategiesUsed': s.strategiesUsed, 'confluenceCount': s.confluenceCount,
    'timeframesAligned': s.timeframesAligned, 'createdAt': s.createdAt.toIso8601String(),
    'closedAt': s.closedAt?.toIso8601String(), 'actualProfit': s.actualProfit,
    'maxFavorableExcursion': s.maxFavorableExcursion,
    'maxAdverseExcursion': s.maxAdverseExcursion, 'aiNotes': s.aiNotes,
    'newsAdjusted': s.newsAdjusted,
  };
}

SignalEntity _signalFromJson(Map<String, dynamic> json) {
  return SignalEntity(
    id: json['id'] as String, symbol: json['symbol'] as String,
    direction: SignalDirection.values.byName(json['direction'] as String),
    entryPrice: (json['entryPrice'] as num).toDouble(),
    stopLoss: (json['stopLoss'] as num).toDouble(),
    takeProfit: (json['takeProfit'] as num).toDouble(),
    confidence: (json['confidence'] as num).toDouble(),
    confidenceLabel: SignalConfidence.values.byName(json['confidenceLabel'] as String),
    status: SignalStatus.values.byName(json['status'] as String),
    indicatorsUsed: (json['indicatorsUsed'] as List).cast<String>(),
    strategiesUsed: (json['strategiesUsed'] as List).cast<String>(),
    confluenceCount: json['confluenceCount'] as int,
    timeframesAligned: json['timeframesAligned'] as int,
    createdAt: DateTime.parse(json['createdAt'] as String),
    closedAt: json['closedAt'] != null ? DateTime.parse(json['closedAt'] as String) : null,
    actualProfit: json['actualProfit'] != null ? (json['actualProfit'] as num).toDouble() : null,
    maxFavorableExcursion: json['maxFavorableExcursion'] != null
        ? (json['maxFavorableExcursion'] as num).toDouble() : null,
    maxAdverseExcursion: json['maxAdverseExcursion'] != null
        ? (json['maxAdverseExcursion'] as num).toDouble() : null,
    aiNotes: json['aiNotes'] as String?,
    newsAdjusted: json['newsAdjusted'] as bool? ?? false,
  );
}
