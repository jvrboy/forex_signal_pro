import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/signals/domain/models/signal_entity.dart';
import 'json_persistence.dart';

final signalCollectionProvider = Provider<CollectionPersistence<SignalEntity>>((ref) {
  final store = ref.watch(jsonPersistenceProvider);
  return CollectionPersistence<SignalEntity>(
    store: store,
    collectionKey: 'signals',
    fromJson: _signalFromJson,
    toJson: _signalToJson,
  );
});

Map<String, dynamic> _signalToJson(SignalEntity s) {
  return {
    'id': s.id,
    'symbol': s.symbol,
    'direction': s.direction.name,
    'entryPrice': s.entryPrice,
    'stopLoss': s.stopLoss,
    'takeProfit': s.takeProfit,
    'confidence': s.confidence,
    'confidenceLabel': s.confidenceLabel.name,
    'status': s.status.name,
    'indicatorsUsed': s.indicatorsUsed,
    'strategiesUsed': s.strategiesUsed,
    'confluenceCount': s.confluenceCount,
    'timeframesAligned': s.timeframesAligned,
    'createdAt': s.createdAt.toIso8601String(),
    'closedAt': s.closedAt?.toIso8601String(),
    'actualProfit': s.actualProfit,
    'maxFavorableExcursion': s.maxFavorableExcursion,
    'maxAdverseExcursion': s.maxAdverseExcursion,
    'aiNotes': s.aiNotes,
    'newsAdjusted': s.newsAdjusted,
  };
}

SignalEntity _signalFromJson(Map<String, dynamic> json) {
  return SignalEntity(
    id: json['id'] as String,
    symbol: json['symbol'] as String,
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
        ? (json['maxFavorableExcursion'] as num).toDouble()
        : null,
    maxAdverseExcursion: json['maxAdverseExcursion'] != null
        ? (json['maxAdverseExcursion'] as num).toDouble()
        : null,
    aiNotes: json['aiNotes'] as String?,
    newsAdjusted: json['newsAdjusted'] as bool? ?? false,
  );
}
