import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/background/news_scheduler.dart';
import 'core/background/signal_monitor_service.dart';
import 'core/network/connection_monitor.dart';
import 'core/persistence/json_persistence.dart';
import 'core/storage/local_database.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  final db = await LocalDatabase.initialize();
  await ConnectionMonitor.instance.initialize();
  await NewsScheduler.initialize();
  await SignalMonitorService.initialize();

  final jsonStore = JsonPersistence(fileName: 'forex_signal_pro_data.json');

  runApp(
    ProviderScope(
      overrides: [
        localDatabaseProvider.overrideWithValue(db),
        jsonPersistenceProvider.overrideWithValue(jsonStore),
      ],
      child: const ForexSignalProApp(),
    ),
  );
}
