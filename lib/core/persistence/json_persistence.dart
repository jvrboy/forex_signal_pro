import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

final jsonPersistenceProvider = Provider<JsonPersistence>((ref) {
  throw UnimplementedError('Must be overridden in main.dart');
});

class JsonPersistence {
  final String _fileName;
  Map<String, String>? _cache;
  bool _loaded = false;

  JsonPersistence({required String fileName}) : _fileName = fileName;

  Future<String> get _filePath async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/$_fileName';
  }

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    final path = await _filePath;
    final file = File(path);
    if (await file.exists()) {
      final content = await file.readAsString();
      final decoded = jsonDecode(content) as Map<String, dynamic>;
      _cache = decoded.map((k, v) => MapEntry(k, v.toString()));
    } else {
      _cache = {};
    }
    _loaded = true;
  }

  Future<String?> read(String key) async {
    await _ensureLoaded();
    return _cache![key];
  }

  Future<void> write(String key, String value) async {
    await _ensureLoaded();
    _cache![key] = value;
    await _flush();
  }

  Future<void> delete(String key) async {
    await _ensureLoaded();
    _cache!.remove(key);
    await _flush();
  }

  Future<List<String>> readList(String key) async {
    final raw = await read(key);
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) return decoded.cast<String>();
      return [];
    } catch (e) {
      print('JsonPersistence: failed to decode list for "$key": $e');
      return [];
    }
  }

  Future<void> writeList(String key, List<String> values) async {
    await write(key, jsonEncode(values));
  }

  Future<void> appendToList(String key, String value) async {
    final list = await readList(key);
    list.add(value);
    await writeList(key, list);
  }

  Future<void> removeFromList(String key, String value) async {
    final list = await readList(key);
    list.remove(value);
    await writeList(key, list);
  }

  Future<Map<String, dynamic>> readMap(String key) async {
    final raw = await read(key);
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) return decoded.cast<String, dynamic>();
      return {};
    } catch (e) {
      print('JsonPersistence: failed to decode map for "$key": $e');
      return {};
    }
  }

  Future<void> writeMap(String key, Map<String, dynamic> value) async {
    await write(key, jsonEncode(value));
  }

  Future<List<Map<String, dynamic>>> readJsonList(String key) async {
    final raw = await read(key);
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) return decoded.cast<Map<String, dynamic>>();
      return [];
    } catch (e) {
      print('JsonPersistence: failed to decode json list for "$key": $e');
      return [];
    }
  }

  Future<void> writeJsonList(String key, List<Map<String, dynamic>> value) async {
    await write(key, jsonEncode(value));
  }

  Future<void> _flush() async {
    final path = await _filePath;
    final file = File(path);
    await file.writeAsString(jsonEncode(_cache!));
  }

  Future<void> clear() async {
    _cache = {};
    _loaded = true;
    await _flush();
  }
}

class CollectionPersistence<T> {
  final JsonPersistence _store;
  final String _collectionKey;
  final T Function(Map<String, dynamic> json) _fromJson;
  final Map<String, dynamic> Function(T item) _toJson;

  CollectionPersistence({
    required JsonPersistence store,
    required String collectionKey,
    required T Function(Map<String, dynamic>) fromJson,
    required Map<String, dynamic> Function(T) toJson,
  })  : _store = store,
        _collectionKey = collectionKey,
        _fromJson = fromJson,
        _toJson = toJson;

  Future<List<T>> getAll() async {
    final items = await _store.readJsonList(_collectionKey);
    return items.map(_fromJson).toList();
  }

  Future<void> saveAll(List<T> items) async {
    await _store.writeJsonList(_collectionKey, items.map(_toJson).toList());
  }

  Future<void> add(T item) async {
    final items = await getAll();
    items.add(item);
    await saveAll(items);
  }

  Future<void> update(Function(T) matcher, T updated) async {
    final items = await getAll();
    final index = items.indexWhere((item) {
      try {
        return matcher(item) as bool;
      } catch (e) {
        print('CollectionPersistence: update matcher error: $e');
        return false;
      }
    });
    if (index != -1) {
      items[index] = updated;
      await saveAll(items);
    }
  }

  Future<void> delete(Function(T) matcher) async {
    final items = await getAll();
    items.removeWhere((item) {
      try {
        return matcher(item) as bool;
      } catch (e) {
        print('CollectionPersistence: delete matcher error: $e');
        return false;
      }
    });
    await saveAll(items);
  }

  Future<void> clear() async {
    await _store.writeJsonList(_collectionKey, []);
  }
}
