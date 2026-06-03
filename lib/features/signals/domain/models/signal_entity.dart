import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

enum SignalDirection { buy, sell }
enum SignalStatus { active, slHit, tpHit, expired, cancelled }
enum SignalConfidence { low, medium, high, veryHigh }

class SignalEntity extends Equatable {
  final String id;
  final String symbol;
  final SignalDirection direction;
  final double entryPrice;
  final double stopLoss;
  final double takeProfit;
  final double confidence;
  final SignalConfidence confidenceLabel;
  final SignalStatus status;
  final List<String> indicatorsUsed;
  final List<String> strategiesUsed;
  final int confluenceCount;
  final int timeframesAligned;
  final DateTime createdAt;
  final DateTime? closedAt;
  final double? actualProfit;
  final double? maxFavorableExcursion;
  final double? maxAdverseExcursion;
  final String? aiNotes;
  final bool newsAdjusted;

  const SignalEntity({
    required this.id,
    required this.symbol,
    required this.direction,
    required this.entryPrice,
    required this.stopLoss,
    required this.takeProfit,
    required this.confidence,
    required this.confidenceLabel,
    required this.status,
    required this.indicatorsUsed,
    required this.strategiesUsed,
    required this.confluenceCount,
    required this.timeframesAligned,
    required this.createdAt,
    this.closedAt,
    this.actualProfit,
    this.maxFavorableExcursion,
    this.maxAdverseExcursion,
    this.aiNotes,
    this.newsAdjusted = false,
  });

  factory SignalEntity.create({
    required String symbol,
    required SignalDirection direction,
    required double entryPrice,
    required double stopLoss,
    required double takeProfit,
    required double confidence,
    required List<String> indicatorsUsed,
    required List<String> strategiesUsed,
    required int confluenceCount,
    required int timeframesAligned,
    String? aiNotes,
    bool newsAdjusted = false,
  }) {
    return SignalEntity(
      id: const Uuid().v4(),
      symbol: symbol,
      direction: direction,
      entryPrice: entryPrice,
      stopLoss: stopLoss,
      takeProfit: takeProfit,
      confidence: confidence,
      confidenceLabel: _confidenceFromScore(confidence),
      status: SignalStatus.active,
      indicatorsUsed: indicatorsUsed,
      strategiesUsed: strategiesUsed,
      confluenceCount: confluenceCount,
      timeframesAligned: timeframesAligned,
      createdAt: DateTime.now(),
      aiNotes: aiNotes,
      newsAdjusted: newsAdjusted,
    );
  }

  static SignalConfidence _confidenceFromScore(double score) {
    if (score >= 0.85) return SignalConfidence.veryHigh;
    if (score >= 0.70) return SignalConfidence.high;
    if (score >= 0.50) return SignalConfidence.medium;
    return SignalConfidence.low;
  }

  double get riskRewardRatio {
    if (direction == SignalDirection.buy) {
      return (takeProfit - entryPrice) / (entryPrice - stopLoss);
    }
    return (entryPrice - takeProfit) / (stopLoss - entryPrice);
  }

  double get pipDistance {
    if (direction == SignalDirection.buy) {
      return (takeProfit - entryPrice) * 10000;
    }
    return (entryPrice - takeProfit) * 10000;
  }

  SignalEntity copyWith({
    SignalStatus? status,
    DateTime? closedAt,
    double? actualProfit,
    double? maxFavorableExcursion,
    double? maxAdverseExcursion,
    String? aiNotes,
    bool? newsAdjusted,
  }) {
    return SignalEntity(
      id: id,
      symbol: symbol,
      direction: direction,
      entryPrice: entryPrice,
      stopLoss: stopLoss,
      takeProfit: takeProfit,
      confidence: confidence,
      confidenceLabel: confidenceLabel,
      status: status ?? this.status,
      indicatorsUsed: indicatorsUsed,
      strategiesUsed: strategiesUsed,
      confluenceCount: confluenceCount,
      timeframesAligned: timeframesAligned,
      createdAt: createdAt,
      closedAt: closedAt ?? this.closedAt,
      actualProfit: actualProfit ?? this.actualProfit,
      maxFavorableExcursion: maxFavorableExcursion ?? this.maxFavorableExcursion,
      maxAdverseExcursion: maxAdverseExcursion ?? this.maxAdverseExcursion,
      aiNotes: aiNotes ?? this.aiNotes,
      newsAdjusted: newsAdjusted ?? this.newsAdjusted,
    );
  }

  @override
  List<Object?> get props => [
    id,
    symbol,
    direction,
    entryPrice,
    stopLoss,
    takeProfit,
    confidence,
    confidenceLabel,
    status,
    indicatorsUsed,
    strategiesUsed,
    confluenceCount,
    timeframesAligned,
    createdAt,
    closedAt,
    actualProfit,
    maxFavorableExcursion,
    maxAdverseExcursion,
    aiNotes,
    newsAdjusted,
  ];
}
