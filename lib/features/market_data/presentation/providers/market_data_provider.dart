import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/deriv_socket_service.dart';
import '../../domain/models/tick.dart';
import '../../domain/models/symbol_info.dart';

final tickStreamProvider = StreamProvider.family<Tick, String>((ref, symbol) {
  final socket = ref.watch(derivSocketProvider);
  final controller = StreamController<Tick>.broadcast();

  final sub = socket.rawMessages.listen((msg) {
    if (msg['msg_type'] == 'tick') {
      try {
        final tick = Tick.fromJson(msg);
        if (tick.symbol == symbol) {
          controller.add(tick);
        }
      } catch (_) {}
    }
  });

  socket.subscribeTicks(symbol);

  ref.onDispose(() {
    socket.unsubscribeTicks(symbol);
    sub.cancel();
    controller.close();
  });

  return controller.stream;
});

final activeSymbolsProvider = FutureProvider<List<SymbolInfo>>((ref) async {
  final socket = ref.watch(derivSocketProvider);
  final completer = Completer<List<SymbolInfo>>();

  final sub = socket.rawMessages.listen((msg) {
    if (msg['msg_type'] == 'active_symbols') {
      final symbols = (msg['active_symbols'] as List)
          .map((e) => SymbolInfo.fromJson(e as Map<String, dynamic>))
          .toList();
      completer.complete(symbols);
    }
  });

  socket.getActiveSymbols();

  ref.onDispose(() => sub.cancel());

  return completer.future.timeout(const Duration(seconds: 10));
});

final forexSymbolsProvider = FutureProvider<List<SymbolInfo>>((ref) async {
  final all = await ref.watch(activeSymbolsProvider.future);
  return all.where((s) => s.market == 'forex').toList();
});
