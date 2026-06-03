import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/signals/domain/neural_tracker/network.dart';
import 'json_persistence.dart';

final nnWeightsProvider = Provider<NnWeightsStore>((ref) {
  final jsonPersistence = ref.watch(jsonPersistenceProvider);
  return NnWeightsStore(jsonPersistence);
});

class NnWeightsStore {
  final JsonPersistence _store;

  NnWeightsStore(this._store);

  static const _key = 'nn_weights';

  Future<void> save(Map<String, dynamic> weights) async {
    await _store.writeMap(_key, weights);
  }

  Future<Map<String, dynamic>> load() async {
    return await _store.readMap(_key);
  }

  Future<bool> hasWeights() async {
    final data = await load();
    return data.isNotEmpty;
  }

  Future<void> saveFromNetwork(SignalScoringNN network) async {
    await save(network.serialize());
  }

  Future<bool> loadIntoNetwork(SignalScoringNN network) async {
    final weights = await load();
    if (weights.isEmpty) return false;
    final restored = SignalScoringNN.deserialize(weights);
    network.layers.clear();
    network.layers.addAll(restored.layers);
    return true;
  }
}
