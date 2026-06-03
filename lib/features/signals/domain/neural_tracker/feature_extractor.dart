import 'dart:typed_data';
import '../models/signal_entity.dart';

class SignalFeatures {
  final double confluenceScore;
  final double timeframeAlignment;
  final double volatilityIndex;
  final double rsiValue;
  final double trendStrength;
  final double hourOfDay;
  final double dayOfWeek;
  final double newsImpact;
  final double spreadWidth;
  final double sessionType;
  final double historicalWinrate;
  final double mfe15min;
  final double mae15min;
  final double volumeSpike;
  final double momentumStrength;
  final double supportResistDistance;
  final double atrMultiplier;
  final double marketRegime;
  final double signalAgeMinutes;
  final double previousSignalCorrelation;

  const SignalFeatures({
    required this.confluenceScore,
    required this.timeframeAlignment,
    required this.volatilityIndex,
    required this.rsiValue,
    required this.trendStrength,
    required this.hourOfDay,
    required this.dayOfWeek,
    required this.newsImpact,
    required this.spreadWidth,
    required this.sessionType,
    required this.historicalWinrate,
    required this.mfe15min,
    required this.mae15min,
    required this.volumeSpike,
    required this.momentumStrength,
    required this.supportResistDistance,
    required this.atrMultiplier,
    required this.marketRegime,
    required this.signalAgeMinutes,
    required this.previousSignalCorrelation,
  });

  Float64List toNormalizedList() {
    return Float64List.fromList([
      _clamp01(confluenceScore),
      _clamp01(timeframeAlignment),
      _clamp01(volatilityIndex),
      _clamp01(rsiValue / 100),
      _clamp01(trendStrength / 100),
      _clamp01(hourOfDay / 24),
      _clamp01(dayOfWeek / 7),
      _clamp01(newsImpact),
      _clamp01(spreadWidth),
      _clamp01(sessionType),
      _clamp01(historicalWinrate),
      _clamp01(mfe15min),
      _clamp01(mae15min),
      _clamp01(volumeSpike),
      _clamp01(momentumStrength),
      _clamp01(supportResistDistance),
      _clamp01(atrMultiplier / 5),
      _clamp01(marketRegime),
      _clamp01(signalAgeMinutes / 1440),
      _clamp01(previousSignalCorrelation),
    ]);
  }

  static double _clamp01(double v) => v.clamp(0.0, 1.0);
}

class FeatureExtractor {
  static const List<String> featureNames = [
    'confluenceScore',
    'timeframeAlignment',
    'volatilityIndex',
    'rsiValue',
    'trendStrength',
    'hourOfDay',
    'dayOfWeek',
    'newsImpact',
    'spreadWidth',
    'sessionType',
    'historicalWinrate',
    'mfe15min',
    'mae15min',
    'volumeSpike',
    'momentumStrength',
    'supportResistDistance',
    'atrMultiplier',
    'marketRegime',
    'signalAgeMinutes',
    'previousSignalCorrelation',
  ];

  static SignalFeatures fromSignal(
    SignalEntity signal, {
    double historicalWinrate = 0.5,
    double mfe15min = 0,
    double mae15min = 0,
    double volumeSpike = 0,
    double momentumStrength = 0.5,
    double supportResistDistance = 0.5,
    double atrMultiplier = 1.5,
    double marketRegime = 0.5,
    double previousSignalCorrelation = 0.5,
    double volatilityIndex = 0.5,
    double rsiValue = 50,
    double trendStrength = 50,
    double spreadWidth = 0.3,
  }) {
    return SignalFeatures(
      confluenceScore: signal.confluenceCount / 20.0,
      timeframeAlignment: signal.timeframesAligned / 6.0,
      volatilityIndex: volatilityIndex,
      rsiValue: rsiValue,
      trendStrength: trendStrength,
      hourOfDay: signal.createdAt.hour.toDouble(),
      dayOfWeek: signal.createdAt.weekday.toDouble(),
      newsImpact: signal.newsAdjusted ? 0.5 : 0,
      spreadWidth: spreadWidth,
      sessionType: _sessionFromHour(signal.createdAt.hour),
      historicalWinrate: historicalWinrate,
      mfe15min: mfe15min,
      mae15min: mae15min,
      volumeSpike: volumeSpike,
      momentumStrength: momentumStrength,
      supportResistDistance: supportResistDistance,
      atrMultiplier: atrMultiplier,
      marketRegime: marketRegime,
      signalAgeMinutes: 0,
      previousSignalCorrelation: previousSignalCorrelation,
    );
  }

  static double _sessionFromHour(int hour) {
    if (hour >= 1 && hour < 9) return 0.0;
    if (hour >= 9 && hour <= 17) return 0.5;
    return 1.0;
  }
}
