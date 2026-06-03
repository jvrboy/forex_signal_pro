import 'dart:async';
import 'dart:io';

class ConnectionMonitor {
  ConnectionMonitor._();

  static final ConnectionMonitor instance = ConnectionMonitor._();

  final _controller = StreamController<bool>.broadcast();
  bool _isConnected = false;

  Stream<bool> get onStatusChange => _controller.stream;
  bool get isConnected => _isConnected;

  Future<void> initialize() async {
    _checkConnection();
    Timer.periodic(const Duration(seconds: 10), (_) => _checkConnection());
  }

  Future<void> _checkConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      final connected = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      if (connected != _isConnected) {
        _isConnected = connected;
        _controller.add(connected);
      }
    } catch (e) {
      print('ConnectionMonitor: check failed: $e');
      if (_isConnected) {
        _isConnected = false;
        _controller.add(false);
      }
    }
  }

  void dispose() {
    _controller.close();
  }
}
