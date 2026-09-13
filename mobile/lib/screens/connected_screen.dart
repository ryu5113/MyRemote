import 'package:flutter/material.dart';
import '../services/websocket_service.dart';
import '../widgets/touchpad.dart';

class ConnectedScreen extends StatelessWidget {
  const ConnectedScreen(
      {super.key, required this.remote, required this.message});

  final WebSocketService remote;
  final TextEditingController message;

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            children: [
              Row(children: [
                const Icon(Icons.circle, color: Colors.green, size: 12),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(remote.status,
                        maxLines: 1, overflow: TextOverflow.ellipsis)),
                IconButton(
                    tooltip: '연결 해제',
                    onPressed: remote.disconnect,
                    icon: const Icon(Icons.link_off)),
              ]),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints:
                        const BoxConstraints(maxWidth: 520, maxHeight: 280),
                    child: Touchpad(send: remote.send),
                  ),
                ),
              ),
              SizedBox(
                height: 48,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: [
                    for (final delta in [-120, 120])
                      _action(
                          delta > 0 ? '위로' : '아래로',
                          () => remote
                              .send({'type': 'mouse_scroll', 'delta': delta})),
                    for (final action in ['down', 'mute', 'up'])
                      _action(
                          {'down': '볼륨−', 'mute': '음소거', 'up': '볼륨+'}[action]!,
                          () => remote
                              .send({'type': 'volume', 'action': action})),
                    for (final action in ['previous', 'play_pause', 'next'])
                      _action(
                          {
                            'previous': '이전',
                            'play_pause': '재생/정지',
                            'next': '다음'
                          }[action]!,
                          () =>
                              remote.send({'type': 'media', 'action': action})),
                    for (final name in [
                      'chrome',
                      'edge',
                      'notepad',
                      'calculator'
                    ])
                      _action(
                          {
                            'chrome': 'Chrome',
                            'edge': 'Edge',
                            'notepad': '메모장',
                            'calculator': '계산기'
                          }[name]!,
                          () => remote.send({'type': 'launch', 'name': name})),
                    _action(
                        'PC 잠금',
                        () =>
                            remote.send({'type': 'system', 'action': 'lock'})),
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
                      _action(
                          key, () => remote.send({'type': 'key', 'key': key})),
                  ]),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: message,
                maxLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) =>
                    remote.send({'type': 'keyboard', 'text': message.text}),
                decoration: const InputDecoration(
                    isDense: true,
                    border: OutlineInputBorder(),
                    labelText: 'PC에 입력할 문자'),
              ),
              const SizedBox(height: 6),
              Row(children: [
                Expanded(
                    child: FilledButton(
                        onPressed: () => remote
                            .send({'type': 'keyboard', 'text': message.text}),
                        child: const Text('PC에 입력'))),
                const SizedBox(width: 8),
                OutlinedButton(
                    onPressed: () => remote.send({'type': 'ping'}),
                    child: const Text('Ping')),
              ]),
            ],
          ),
        ),
      );

  Widget _action(String label, VoidCallback onPressed) => Padding(
        padding: const EdgeInsets.only(right: 6),
        child: ActionChip(
            label: Text(label),
            onPressed: onPressed,
            visualDensity: VisualDensity.compact),
      );
}
