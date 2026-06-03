import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/persistence/json_persistence.dart';
import '../../../core/persistence/signal_json_adapter.dart';
import '../../../core/persistence/nn_weights_adapter.dart';
import '../domain/models/signal_entity.dart';

abstract class SignalRepository {
  Future<List<SignalEntity>> getSignals();
  Future<List<SignalEntity>> getActiveSignals();
  Future<List<SignalEntity>> getSignalsBySymbol(String symbol);
  Future<SignalEntity?> getSignal(String id);
  Future<void> addSignal(SignalEntity signal);
  Future<void> updateSignal(SignalEntity signal);
  Future<double> getWinRate(String symbol);
  Future<Map<String, double>> getAllWinRates();
  Future<void> clearSignals();
  Future<List<SignalEntity>> getRecentSignals(int limit);
}

final signalRepositoryProvider = Provider<SignalRepository>((ref) {
  final collection = ref.watch(signalCollectionProvider);
  return PersistentSignalRepository(collection: collection);
});

class PersistentSignalRepository implements SignalRepository {
  final CollectionPersistence<SignalEntity> _collection;
  List<SignalEntity>? _cache;

  PersistentSignalRepository({required CollectionPersistence<SignalEntity> collection})
      : _collection = collection;

  Future<List<SignalEntity>> _load() async {
    if (_cache == null) {
      _cache = await _collection.getAll();
    }
    return _cache!;
  }

  Future<void> _save() async {
    if (_cache != null) {
      await _collection.saveAll(_cache!);
    }
  }

  @override
  Future<List<SignalEntity>> getSignals() async {
    final signals = await _load();
    return List.unmodifiable(signals);
  }

  @override
  Future<List<SignalEntity>> getActiveSignals() async {
    final signals = await _load();
    return signals.where((s) => s.status == SignalStatus.active).toList();
  }

  @override
  Future<List<SignalEntity>> getSignalsBySymbol(String symbol) async {
    final signals = await _load();
    return signals.where((s) => s.symbol == symbol).toList();
  }

  @override
  Future<SignalEntity?> getSignal(String id) async {
    final signals = await _load();
    try {
      return signals.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> addSignal(SignalEntity signal) async {
    final signals = await _load();
    signals.add(signal);
    await _save();
  }

  @override
  Future<void> updateSignal(SignalEntity signal) async {
    final signals = await _load();
    final index = signals.indexWhere((s) => s.id == signal.id);
    if (index != -1) {
      signals[index] = signal;
      await _save();
    }
  }

  @override
  Future<double> getWinRate(String symbol) async {
    final signals = await _load();
    final symbolSignals = signals
        .where((s) => s.symbol == symbol && s.closedAt != null)
        .toList();
    if (symbolSignals.isEmpty) return 0;
    final wins = symbolSignals.where((s) => s.status == SignalStatus.tpHit).length;
    return wins / symbolSignals.length;
  }

  @override
  Future<Map<String, double>> getAllWinRates() async {
    final signals = await _load();
    final closed = signals.where((s) => s.closedAt != null).toList();
    final symbolGroups = <String, List<SignalEntity>>{};
    for (final s in closed) {
      symbolGroups.putIfAbsent(s.symbol, () => []).add(s);
    }
    return symbolGroups.map((symbol, group) {
      final wins = group.where((s) => s.status == SignalStatus.tpHit).length;
      return MapEntry(symbol, wins / group.length);
    });
  }

  @override
  Future<void> clearSignals() async {
    _cache = [];
    await _collection.clear();
  }

  @override
  Future<List<SignalEntity>> getRecentSignals(int limit) async {
    final signals = await _load();
    signals.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return signals.take(limit).toList();
  }
}
