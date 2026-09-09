import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:myremote/services/websocket_service.dart';

void main() {
  test('invalid address is rejected without connecting', () async {
    final remote = WebSocketService();
    addTearDown(remote.dispose);
    await remote.connect('not-an-ip', 'test');
    expect(remote.connected, false);
    expect(remote.busy, false);
    expect(remote.status, contains('IPv4'));
  });

  test('auth header, message round trip, disconnect and reconnect', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final port = server.port;
    addTearDown(() => server.close(force: true));
    final sockets = <WebSocket>[];
    addTearDown(() async {
      for (final socket in sockets) {
        await socket.close();
      }
    });
    server.listen((request) async {
      expect(request.headers.value('Authorization'), 'Bearer test-access-key');
      final socket = await WebSocketTransformer.upgrade(request);
      sockets.add(socket);
      socket.listen((event) => socket.add(event));
    });
    final remote = WebSocketService();
    addTearDown(remote.dispose);
    await remote.connect('127.0.0.1', 'test-access-key', port: port);
    expect(remote.connected, true);
    final received = Completer<void>();
    remote.addListener(() {
      if (remote.messages.isNotEmpty && !received.isCompleted) {
        received.complete();
      }
    });
    remote.send({'type': 'test_message', 'text': '안녕하세요'});
    await received.future.timeout(const Duration(seconds: 3));
    expect(jsonDecode(remote.messages.first)['text'], '안녕하세요');
    remote.disconnect();
    expect(remote.connected, false);
    await remote.connect('127.0.0.1', 'test-access-key', port: port);
    expect(remote.connected, true);
    remote.disconnect();
  });
}
