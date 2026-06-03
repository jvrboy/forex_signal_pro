import 'dart:typed_data';
import '../models/signal_entity.dart';
import 'network.dart';
import 'feature_extractor.dart';

enum FailureCause {
  tightStops,
  wrongDirection,
  badTiming,
  newsImpact,
  marketRegimeShift,
  lowConfluence,
  highVolatility,
  spreadWidening,
}

class FailureReport {
  final FailureCause topCause;
  final String description;
  final List<FailureCause> causes;
  final List<double> featureImportances;
  final Map<String, dynamic> recommendedActions;
  final double estimatedGain;

  const FailureReport({
    required this.topCause,
    required this.description,
    required this.causes,
    required this.featureImportances,
    required this.recommendedActions,
    required this.estimatedGain,
  });
}

class FailureAnalyzer {
  final SignalScoringNN _nn;
  final List<SignalEntity> _recentFailures;
  final List<SignalEntity> _recentSuccesses;

  FailureAnalyzer({
    required SignalScoringNN nn,
    List<SignalEntity> recentFailures = const [],
    List<SignalEntity> recentSuccesses = const [],
  }) : _nn = nn,
       _recentFailures = recentFailures,
       _recentSuccesses = recentSuccesses;

  Future<FailureReport> analyze(
    SignalEntity failedSignal, {
    double historicalWinrate = 0.5,
  }) async {
    final features = FeatureExtractor.fromSignal(
      failedSignal,
      historicalWinrate: historicalWinrate,
    );
    final featureList = features.toNormalizedList();
    final importances = _nn.featureImportance(
      baselineFeatures: featureList,
    );

    final causes = <FailureCause>[];
    if (importances[1] > 0.15) causes.add(FailureCause.lowConfluence);
    if (importances[2] > 0.15) causes.add(FailureCause.highVolatility);
    if (importances[7] > 0.15) causes.add(FailureCause.newsImpact);
    if (importances[16] < 0.2) causes.add(FailureCause.tightStops);
    if (importances[17] > 0.2) causes.add(FailureCause.marketRegimeShift);
    if (importances[8] > 0.15) causes.add(FailureCause.spreadWidening);

    final topCause = causes.isNotEmpty ? causes.first : FailureCause.lowConfluence;
    final description = _describe(topCause, failedSignal);

    final actions = _recommendActions(topCause, failedSignal);
    final estimatedGain = _estimateGain(topCause);

    return FailureReport(
      topCause: topCause,
      description: description,
      causes: causes,
      featureImportances: importances,
      recommendedActions: actions,
      estimatedGain: estimatedGain,
    );
  }

  String _describe(FailureCause cause, SignalEntity signal) {
    switch (cause) {
      case FailureCause.tightStops:
        return 'Stop loss was too tight (${signal.stopLoss.toStringAsFixed(5)}) relative to ATR. '
            'Price hit SL before reversing toward target. Consider increasing ATR multiplier.';
      case FailureCause.wrongDirection:
        return 'Overall market direction was opposite to signal. '
            'Higher timeframe trend was against the trade direction.';
      case FailureCause.badTiming:
        return 'Entry timing was premature. Price moved in the right direction '
            'but only after the signal had expired. Consider wider entry zones.';
      case FailureCause.newsImpact:
        return 'High-impact news event occurred during the trade. '
            'News-related volatility triggered the stop loss.';
      case FailureCause.marketRegimeShift:
        return 'Market regime changed from trending to ranging (or vice versa) '
            'during the trade, invalidating the strategy assumptions.';
      case FailureCause.lowConfluence:
        return 'Insufficient strategy agreement. Only ${signal.confluenceCount} '
            'strategies aligned - consider increasing minimum confluence threshold.';
      case FailureCause.highVolatility:
        return 'Volatility spike exceeded normal conditions. '
            'ATR was ${signal.riskRewardRatio.toStringAsFixed(1)}x normal.';
      case FailureCause.spreadWidening:
        return 'Spread widened significantly during low liquidity hours. '
            'Entry/exit slippage reduced profitability.';
    }
  }

  Map<String, dynamic> _recommendActions(FailureCause cause, SignalEntity signal) {
    switch (cause) {
      case FailureCause.tightStops:
        return {'atrMultiplier': 2.0, 'note': 'Increased from 1.5 to 2.0'};
      case FailureCause.wrongDirection:
        return {'requireTrendFilter': true, 'note': 'Added higher timeframe trend alignment check'};
      case FailureCause.badTiming:
        return {'entryZonePips': 10, 'note': 'Widened entry zone by 10 pips'};
      case FailureCause.newsImpact:
        return {'newsFilter': true, 'note': 'Enable news filter to skip signals 2h before high-impact events'};
      case FailureCause.marketRegimeShift:
        return {'regimeFilter': true, 'note': 'Only trade when market regime matches strategy'};
      case FailureCause.lowConfluence:
        return {'minConfluence': signal.confluenceCount + 1, 'note': 'Increased minimum confluence'};
      case FailureCause.highVolatility:
        return {'maxAtrMultiplier': 3.0, 'note': 'Skip trades when ATR > 3x normal'};
      case FailureCause.spreadWidening:
        return {'maxSpreadPips': 2, 'note': 'Skip trades when spread exceeds 2 pips'};
    }
  }

  double _estimateGain(FailureCause cause) {
    switch (cause) {
      case FailureCause.tightStops: return 0.05;
      case FailureCause.wrongDirection: return 0.08;
      case FailureCause.badTiming: return 0.03;
      case FailureCause.newsImpact: return 0.06;
      case FailureCause.marketRegimeShift: return 0.07;
      case FailureCause.lowConfluence: return 0.04;
      case FailureCause.highVolatility: return 0.05;
      case FailureCause.spreadWidening: return 0.02;
    }
  }
}
