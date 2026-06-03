import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../../features/signals/domain/models/signal_entity.dart';

final localDatabaseProvider = Provider<LocalDatabase>((ref) {
  throw UnimplementedError('Must be overridden in main.dart');
});

class LocalDatabase {
  Isar? _isar;
  bool _initialized = false;

  Isar get isar {
    if (!_initialized || _isar == null) {
      throw StateError('Database not initialized');
    }
    return _isar!;
  }

  bool get isReady => _initialized;

  static Future<LocalDatabase> initialize() async {
    final db = LocalDatabase();
    try {
      final dir = await getApplicationDocumentsDirectory();
      db._isar = await Isar.open(
        [],
        directory: dir.path,
        name: 'forex_signal_pro',
      );
      db._initialized = true;
    } catch (e) {
      db._initialized = false;
    }
    return db;
  }

  Future<void> close() async {
    if (_isar != null) {
      await _isar!.close();
      _isar = null;
      _initialized = false;
    }
  }
}
