import 'package:flutter/material.dart';
import 'services/websocket_service.dart';
import 'widgets/touchpad.dart';

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
  final accessKey = TextEditingController();
  final message = TextEditingController(text: 'Hello Windows');
  final remote = WebSocketService();

  @override
  void dispose() {
    remote.dispose();
    ip.dispose();
    accessKey.dispose();
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
                Text('내 PC에 연결',
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                const Text('PC와 휴대폰을 같은 Wi-Fi에 연결한 뒤 Agent에 표시된 IP를 입력하세요.'),
                const SizedBox(height: 24),
                TextField(
                  controller: ip,
                  enabled: !remote.busy && !remote.connected,
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'PC IP 주소',
                      hintText: '192.168.0.100'),
                ),
                const SizedBox(height: 12),
                TextField(
                    controller: accessKey,
                    obscureText: true,
                    autocorrect: false,
                    decoration:
                        const InputDecoration(labelText: 'Agent에 표시된 연결 키')),
                FilledButton.icon(
                  onPressed: remote.busy
                      ? null
                      : () {
                          if (remote.connected) {
                            remote.disconnect();
                          } else {
                            remote.connect(
                                ip.text.trim(), accessKey.text.trim());
                          }
                        },
                  icon: Icon(remote.connected ? Icons.link_off : Icons.link),
                  label: Text(remote.busy
                      ? '연결 중…'
                      : remote.connected
                          ? '연결 해제'
                          : '연결'),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.circle,
                      color: remote.connected ? Colors.green : Colors.grey),
                  title: Text(remote.status),
                ),
                const Divider(),
                if (remote.connected) ...[
                  Touchpad(send: remote.send),
                  Wrap(spacing: 8, children: [
                    for (final delta in [-120, 120])
                      OutlinedButton(
                          onPressed: () => remote
                              .send({'type': 'mouse_scroll', 'delta': delta}),
                          child: Text(delta > 0 ? '위로 스크롤' : '아래로 스크롤')),
                    for (final action in ['down', 'mute', 'up'])
                      OutlinedButton(
                          onPressed: () =>
                              remote.send({'type': 'volume', 'action': action}),
                          child: Text({
                            'down': '볼륨 −',
                            'mute': '음소거',
                            'up': '볼륨 +'
                          }[action]!)),
                    for (final action in ['previous', 'play_pause', 'next'])
                      OutlinedButton(
                          onPressed: () =>
                              remote.send({'type': 'media', 'action': action}),
                          child: Text({
                            'previous': '이전',
                            'play_pause': '재생/일시정지',
                            'next': '다음'
                          }[action]!)),
                    for (final key in [
                      'enter',
                      'escape',
                      'tab',
                      'backspace',
                      'left',
                      'up',
                      'right',
                      'down'
                    ])
                      ActionChip(
                          label: Text(key),
                          onPressed: () =>
                              remote.send({'type': 'key', 'key': key})),
                  ]),
                ],
                const SizedBox(height: 16),
                TextField(
                    controller: message,
                    maxLength: 2000,
                    maxLines: 3,
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(), labelText: '테스트 메시지')),
                FilledButton(
                    onPressed: remote.connected
                        ? () => remote.send(
                            {'type': 'test_message', 'text': message.text})
                        : null,
                    child: const Text('PC로 메시지 보내기')),
                FilledButton(
                    onPressed: remote.connected
                        ? () => remote
                            .send({'type': 'keyboard', 'text': message.text})
                        : null,
                    child: const Text('PC의 현재 입력란에 입력')),
                OutlinedButton(
                    onPressed: remote.connected
                        ? () => remote.send({'type': 'ping'})
                        : null,
                    child: const Text('연결 확인 (Ping)')),
                const SizedBox(height: 24),
                Text('연결 기록', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                SelectableText(remote.messages.isEmpty
                    ? '아직 기록이 없습니다.'
                    : remote.messages.join('\n\n')),
              ]),
            ),
          ),
        ),
      );
}
