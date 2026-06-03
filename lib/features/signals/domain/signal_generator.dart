import 'models/signal_entity.dart';

class SignalGenerator {
  double _currentPrice;
  final double _atr;
  final int _confluenceThreshold;

  SignalGenerator({
    required double currentPrice,
    required double atr,
    int confluenceThreshold = 3,
  }) : _currentPrice = currentPrice,
       _atr = atr,
       _confluenceThreshold = confluenceThreshold;

  void updatePrice(double price) {
    _currentPrice = price;
  }

  SignalEntity? generateSignal({
    required String symbol,
    required SignalDirection direction,
    required int confluenceCount,
    required int timeframesAligned,
    required List<String> indicatorsUsed,
    required List<String> strategiesUsed,
    double confidenceOverride = 0,
    bool newsAdjusted = false,
    double atrMultiplier = 1.5,
    double minConfidence = 0.5,
  }) {
    if (confluenceCount < _confluenceThreshold) return null;

    final confidence = confidenceOverride > 0
        ? confidenceOverride
        : _calculateConfidence(confluenceCount, timeframesAligned, newsAdjusted);

    if (confidence < minConfidence) return null;

    final entryPrice = _currentPrice;
    final atrDistance = _atr * atrMultiplier;

    double stopLoss, takeProfit;
    if (direction == SignalDirection.buy) {
      stopLoss = entryPrice - atrDistance;
      takeProfit = entryPrice + atrDistance * 2;
    } else {
      stopLoss = entryPrice + atrDistance;
      takeProfit = entryPrice - atrDistance * 2;
    }

    return SignalEntity.create(
      symbol: symbol,
      direction: direction,
      entryPrice: entryPrice,
      stopLoss: stopLoss,
      takeProfit: takeProfit,
      confidence: confidence,
      indicatorsUsed: indicatorsUsed,
      strategiesUsed: strategiesUsed,
      confluenceCount: confluenceCount,
      timeframesAligned: timeframesAligned,
      newsAdjusted: newsAdjusted,
    );
  }

  double _calculateConfidence(int confluence, int timeframes, bool news) {
    double score = 0;
    score += (confluence / 20.0) * 0.35;
    score += (timeframes / 6.0) * 0.30;
    score += 0.20;
    if (news) score *= 0.7;
    return score.clamp(0.0, 1.0);
  }
}
