import 'dart:typed_data';
import '../models/signal_entity.dart';
import 'network.dart';
import 'failure_analyzer.dart';
import 'feature_extractor.dart';

class SelfFixAction {
  final String description;
  final String parameter;
  final dynamic oldValue;
  final dynamic newValue;
  final DateTime appliedAt;

  const SelfFixAction({
    required this.description,
    required this.parameter,
    required this.oldValue,
    required this.newValue,
    required this.appliedAt,
  });

  Map<String, dynamic> toJson() => {
    'description': description,
    'parameter': parameter,
    'oldValue': oldValue,
    'newValue': newValue,
    'appliedAt': appliedAt.toIso8601String(),
  };
}

class SelfFixEngine {
  final SignalScoringNN _nn;
  final FailureAnalyzer _analyzer;
  final List<SignalEntity> _allSignals;
  final double _failureThreshold;

  Map<String, dynamic> _config = {
    'atrMultiplier': 1.5,
    'minConfluence': 3,
    'requireTrendFilter': false,
    'newsFilter': false,
    'entryZonePips': 5,
    'maxAtrMultiplier': 5.0,
    'maxSpreadPips': 5,
    'regimeFilter': false,
  };

  List<SelfFixAction> _fixHistory = [];

  SelfFixEngine({
    required SignalScoringNN nn,
    required FailureAnalyzer analyzer,
    List<SignalEntity> allSignals = const [],
    double failureThreshold = 0.15,
  }) : _nn = nn,
       _analyzer = analyzer,
       _allSignals = allSignals,
       _failureThreshold = failureThreshold;

  Map<String, dynamic> get config => Map.unmodifiable(_config);
  List<SelfFixAction> get fixHistory => List.unmodifiable(_fixHistory);

  Future<bool> shouldSelfFix(String symbol) async {
    final symbolSignals = _allSignals
        .where((s) => s.symbol == symbol && s.closedAt != null)
        .toList();
    if (symbolSignals.length < 10) return false;

    final failures = symbolSignals.where((s) => s.status == SignalStatus.slHit).length;
    final failureRate = failures / symbolSignals.length;
    return failureRate > _failureThreshold;
  }

  Future<Map<String, dynamic>> applySelfFix(String symbol) async {
    if (!await shouldSelfFix(symbol)) {
      return {'applied': false, 'reason': 'Failure rate below threshold'};
    }

    final changes = <String, dynamic>{};
    final failedSignals = _allSignals
        .where((s) => s.symbol == symbol && s.status == SignalStatus.slHit)
        .toList();

    for (final signal in failedSignals.take(5)) {
      final report = await _analyzer.analyze(signal);
      for (final entry in report.recommendedActions.entries) {
        if (entry.key != 'note') {
          final oldValue = _config[entry.key];
          if (oldValue != entry.value) {
            _config[entry.key] = entry.value;
            changes[entry.key] = {'from': oldValue, 'to': entry.value};
            _fixHistory.add(SelfFixAction(
              description: '${report.description} → ${entry.key} = ${entry.value}',
              parameter: entry.key,
              oldValue: oldValue,
              newValue: entry.value,
              appliedAt: DateTime.now(),
            ));
          }
        }
      }
    }

    return {
      'applied': changes.isNotEmpty,
      'changes': changes,
      'fixCount': _fixHistory.length,
    };
  }

  Future<void> trainOnRecentData(List<TrainingExample> examples) async {
    if (examples.length < 10) return;
    await _nn.train(examples, epochs: 20);
  }

  double evaluateSignal(SignalEntity signal, {double historicalWinrate = 0.5}) {
    final features = FeatureExtractor.fromSignal(
      signal,
      historicalWinrate: historicalWinrate,
    );
    return _nn.predict(features.toNormalizedList());
  }

  Map<String, dynamic> serialize() {
    return {
      'config': _config,
      'fixHistory': _fixHistory.map((f) => f.toJson()).toList(),
    };
  }
}
