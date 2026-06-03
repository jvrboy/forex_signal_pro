import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../constants/app_constants.dart';
import 'messages/deriv_request.dart';
import 'messages/deriv_response.dart';

enum ConnectionState { disconnected, connecting, connected, reconnecting }

class DerivSocketService {
  WebSocketChannel? _channel;
  final _rawMessageController = StreamController<Map<String, dynamic>>.broadcast();
  final _typedMessageController = StreamController<DeriveResponse>.broadcast();
  final _stateController = StreamController<ConnectionState>.broadcast();
  final _pendingRequests = <int, Completer<DeriveResponse>>{};
  Timer? _pingTimer;
  int _reconnectAttempts = 0;
  int _nextReqId = 1;
  String _appId = AppConstants.derivAppId;
  String? _authToken;
  bool _disposed = false;
  final _tickSubscriptions = <String, String>{};

  ConnectionState _state = ConnectionState.disconnected;
  ConnectionState get state => _state;

  Stream<Map<String, dynamic>> get rawMessages => _rawMessageController.stream;
  Stream<DeriveResponse> get typedMessages => _typedMessageController.stream;
  Stream<ConnectionState> get stateStream => _stateController.stream;

  void _updateState(ConnectionState newState) {
    _state = newState;
    if (!_disposed) _stateController.add(newState);
  }

  Future<void> connect({String? appId, String? authToken}) async {
    if (_state == ConnectionState.connecting || _state == ConnectionState.connected) return;

    _appId = appId ?? _appId;
    _authToken = authToken;
    _updateState(ConnectionState.connecting);

    try {
      final uri = Uri.parse('${AppConstants.derivWsUrl}?app_id=$_appId');
      _channel = WebSocketChannel.connect(uri);

      await _channel!.ready;
      _reconnectAttempts = 0;
      _updateState(ConnectionState.connected);
      _startPing();

      _channel!.stream.listen(
        (data) {
          try {
            final decoded = jsonDecode(data as String) as Map<String, dynamic>;
            _rawMessageController.add(decoded);
            final typed = DeriveResponse.fromJson(decoded);
            _typedMessageController.add(typed);

            if (typed.reqId != null && _pendingRequests.containsKey(typed.reqId)) {
              _pendingRequests[typed.reqId]!.complete(typed);
              _pendingRequests.remove(typed.reqId);
            }
            if (typed.isError && typed.reqId != null) {
              _pendingRequests.remove(typed.reqId);
            }
          } catch (e) {
            print('DerivSocket: message parse error: $e');
          }
        },
        onError: (_) => _handleDisconnect(),
        onDone: () => _handleDisconnect(),
      );

      if (_authToken != null) {
        sendRequest(DeriveRequest.authorize(_authToken!));
      }
    } catch (e) {
      _updateState(ConnectionState.disconnected);
      _reconnect();
    }
  }

  int _nextId() => _nextReqId++;

  void _startPing() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(
      const Duration(seconds: AppConstants.wsPingIntervalSeconds),
      (_) => sendRequest(DeriveRequest.ping()),
    );
  }

  void _handleDisconnect() {
    _pingTimer?.cancel();
    _channel = null;
    _pendingRequests.forEach((_, completer) {
      completer.completeError(ConnectionException('Disconnected'));
    });
    _pendingRequests.clear();
    if (_disposed) {
      _updateState(ConnectionState.disconnected);
      return;
    }
    _reconnect();
  }

  void _reconnect() {
    if (_reconnectAttempts >= AppConstants.wsReconnectMaxRetries) {
      _updateState(ConnectionState.disconnected);
      return;
    }
    _updateState(ConnectionState.reconnecting);
    _reconnectAttempts++;
    final delay = Duration(seconds: _reconnectAttempts * _reconnectAttempts);
    Future.delayed(delay, () => connect());
  }

  void _send(Map<String, dynamic> message) {
    if (_channel != null && _state == ConnectionState.connected) {
      _channel!.sink.add(jsonEncode(message));
    }
  }

  void sendRequest(DeriveRequest request) {
    _send(request.toJson());
  }

  Future<DeriveResponse> sendRequestAwait(DeriveRequest request, {Duration? timeout}) {
    final reqId = _nextId();
    final reqWithId = DeriveRequest(type: request.type, params: request.params, reqId: reqId);
    final completer = Completer<DeriveResponse>();
    _pendingRequests[reqId] = completer;
    _send(reqWithId.toJson());

    final timer = timeout != null
        ? Timer(timeout, () {
            if (!completer.isCompleted) {
              _pendingRequests.remove(reqId);
              completer.completeError(TimeoutException('Request timed out: ${request.type.key}'));
            }
          })
        : null;

    return completer.future.then((response) {
      timer?.cancel();
      return response;
    }).catchError((e) {
      timer?.cancel();
      throw e;
    });
  }

  Future<DeriveResponse> authorize(String token) async {
    final req = DeriveRequest.authorize(token);
    return sendRequestAwait(req, timeout: const Duration(seconds: 10));
  }

  Future<void> subscribeTicks(String symbol) async {
    final response = await sendRequestAwait(
      DeriveRequest.subscribeTicks(symbol),
      timeout: const Duration(seconds: 10),
    );
    final subId = response.data?['subscription']?['id'] as String?;
    if (subId != null) {
      _tickSubscriptions[symbol] = subId;
    }
  }

  void unsubscribeTicks(String symbol) {
    final subId = _tickSubscriptions.remove(symbol);
    if (subId != null) {
      sendRequest(DeriveRequest.forget(subId));
    }
  }

  void unsubscribeAllTicks() {
    for (final subId in _tickSubscriptions.values) {
      sendRequest(DeriveRequest.forget(subId));
    }
    _tickSubscriptions.clear();
  }

  void getActiveSymbols() {
    sendRequest(DeriveRequest.activeSymbols());
  }

  void getTickHistory(String symbol, {int count = 100}) {
    sendRequest(DeriveRequest.tickHistory(symbol, count: count));
  }

  void getPortfolio() {
    sendRequest(DeriveRequest.portfolio());
  }

  void getProfitTable({int limit = 50, int offset = 0}) {
    sendRequest(DeriveRequest.profitTable(limit: limit, offset: offset));
  }

  void getBalance() {
    sendRequest(DeriveRequest.balance());
  }

  void buyContract(String contractId, double amount) {
    sendRequest(DeriveRequest.buy(contractId, amount));
  }

  void sellContract(String contractId) {
    sendRequest(DeriveRequest.sell(contractId));
  }

  Future<void> disconnect() async {
    _disposed = true;
    _pingTimer?.cancel();
    await _channel?.sink.close();
    _channel = null;
    _pendingRequests.forEach((_, completer) {
      if (!completer.isCompleted) completer.completeError(ConnectionException('Disconnected'));
    });
    _pendingRequests.clear();
    _updateState(ConnectionState.disconnected);
  }

  void dispose() {
    _disposed = true;
    _pingTimer?.cancel();
    _channel?.sink.close();
    _rawMessageController.close();
    _typedMessageController.close();
    _stateController.close();
    _pendingRequests.forEach((_, completer) {
      if (!completer.isCompleted) completer.completeError(ConnectionException('Disposed'));
    });
    _pendingRequests.clear();
  }
}

class ConnectionException implements Exception {
  final String message;
  const ConnectionException(this.message);
  @override
  String toString() => 'ConnectionException: $message';
}

final derivSocketProvider = Provider<DerivSocketService>((ref) {
  final service = DerivSocketService();
  ref.onDispose(() => service.dispose());
  return service;
});

final connectionStateProvider = StreamProvider<ConnectionState>((ref) {
  final service = ref.watch(derivSocketProvider);
  return service.stateStream;
});

final typedMessageProvider = StreamProvider<DeriveResponse>((ref) {
  final service = ref.watch(derivSocketProvider);
  return service.typedMessages;
});
