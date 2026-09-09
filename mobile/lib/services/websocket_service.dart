import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

class WebSocketService extends ChangeNotifier {
  WebSocket? _socket;
  StreamSubscription<dynamic>? _subscription;
  int _generation = 0;
  bool _disposed = false;
  bool busy = false;
  String status = '연결되지 않음';
  final List<String> messages = [];
  bool get connected => _socket?.readyState == WebSocket.open;

  void _update() { if (!_disposed) notifyListeners(); }
  void _log(String value) {
    messages.insert(0, value);
    if (messages.length > 30) messages.removeLast();
  }

  Future<void> connect(String host) async {
    if (busy || connected) return;
    final address = InternetAddress.tryParse(host);
    if (address == null || address.type != InternetAddressType.IPv4) {
      status = '올바른 IPv4 주소를 입력하세요.';
      _update();
      return;
    }
    final generation = ++_generation;
    busy = true;
    status = '연결 중…';
    _update();
    final pending = WebSocket.connect(Uri(scheme: 'ws', host: host, port: 8765, path: '/ws').toString());
    var expired = false;
    pending.then((socket) {
      if (expired || _disposed || generation != _generation) socket.close();
    }, onError: (Object _) {});
    try {
      final socket = await pending.timeout(const Duration(seconds: 5));
      if (_disposed || generation != _generation) { await socket.close(); return; }
      _socket = socket;
      socket.pingInterval = const Duration(seconds: 20);
      status = '연결됨 · $host';
      _subscription = socket.listen((dynamic event) {
        if (_disposed || generation != _generation) return;
        _log(event.toString());
        _update();
      }, onDone: () => _ended(generation), onError: (Object error) => _ended(generation), cancelOnError: true);
    } catch (error) {
      expired = true;
      if (!_disposed && generation == _generation) {
        status = '연결 실패 · PC IP와 Agent 실행 상태를 확인하세요.';
        _log(error.toString());
      }
    } finally {
      if (!_disposed && generation == _generation) { busy = false; _update(); }
    }
  }

  void _ended(int generation) {
    if (_disposed || generation != _generation) return;
    _socket?.close();
    _socket = null;
    status = '연결이 종료되었습니다.';
    _update();
  }

  void send(Map<String, dynamic> command) {
    if (!connected) return;
    try { _socket!.add(jsonEncode(command)); }
    catch (_) { _ended(_generation); }
  }

  void disconnect() {
    ++_generation;
    _subscription?.cancel();
    _subscription = null;
    _socket?.close();
    _socket = null;
    busy = false;
    status = '연결되지 않음';
    _update();
  }

  @override
  void dispose() { _disposed = true; disconnect(); super.dispose(); }
}
