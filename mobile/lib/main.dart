import 'package:flutter/material.dart';
import 'services/websocket_service.dart';

void main() => runApp(const MyRemoteApp());

class MyRemoteApp extends StatelessWidget {
  const MyRemoteApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'MyRemote',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
        home: const RemotePage(),
      );
}

class RemotePage extends StatefulWidget {
  const RemotePage({super.key});
  @override
  State<RemotePage> createState() => _RemotePageState();
}

class _RemotePageState extends State<RemotePage> {
  final ip = TextEditingController();
  final message = TextEditingController(text: 'Hello Windows');
  final remote = WebSocketService();

  @override
  void dispose() {
    remote.dispose();
    ip.dispose();
    message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('MyRemote')),
        body: AnimatedBuilder(
          animation: remote,
          builder: (context, _) => Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: ListView(padding: const EdgeInsets.all(24), children: [
                Text('내 PC에 연결', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                const Text('PC와 휴대폰을 같은 Wi-Fi에 연결한 뒤 Agent에 표시된 IP를 입력하세요.'),
                const SizedBox(height: 24),
                TextField(
                  controller: ip,
                  enabled: !remote.busy && !remote.connected,
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'PC IP 주소', hintText: '192.168.0.100'),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: remote.busy ? null : () {
                    if (remote.connected) {
                      remote.disconnect();
                    } else {
                      remote.connect(ip.text.trim());
                    }
                  },
                  icon: Icon(remote.connected ? Icons.link_off : Icons.link),
                  label: Text(remote.busy ? '연결 중…' : remote.connected ? '연결 해제' : '연결'),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.circle, color: remote.connected ? Colors.green : Colors.grey),
                  title: Text(remote.status),
                ),
                const Divider(),
                const SizedBox(height: 16),
                TextField(controller: message, maxLength: 2000, maxLines: 3,
                  decoration: const InputDecoration(border: OutlineInputBorder(), labelText: '테스트 메시지')),
                FilledButton(onPressed: remote.connected ? () => remote.send({'type': 'test_message', 'text': message.text}) : null,
                  child: const Text('PC로 메시지 보내기')),
                OutlinedButton(onPressed: remote.connected ? () => remote.send({'type': 'ping'}) : null,
                  child: const Text('연결 확인 (Ping)')),
                const SizedBox(height: 24),
                Text('연결 기록', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                SelectableText(remote.messages.isEmpty ? '아직 기록이 없습니다.' : remote.messages.join('\n\n')),
              ]),
            ),
          ),
        ),
      );
}
