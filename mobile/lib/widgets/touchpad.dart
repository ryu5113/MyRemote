import 'package:flutter/material.dart';

class Touchpad extends StatefulWidget {
  const Touchpad({super.key, required this.send});
  final void Function(Map<String, dynamic>) send;
  @override
  State<Touchpad> createState() => _TouchpadState();
}

class _TouchpadState extends State<Touchpad> {
  double x = 0, y = 0, scroll = 0;

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'PC 터치패드. 한 손가락 이동, 두 손가락 스크롤, 탭 좌클릭, 길게 눌러 우클릭',
        child: GestureDetector(
          onScaleStart: (_) {
            x = 0;
            y = 0;
            scroll = 0;
          },
          onScaleUpdate: (details) {
            if (details.pointerCount >= 2) {
              x = 0;
              y = 0;
              scroll += details.focalPointDelta.dy * -8;
              final delta = scroll.truncate().clamp(-1200, 1200);
              if (delta != 0) {
                widget.send({'type': 'mouse_scroll', 'delta': delta});
                scroll -= delta;
              }
              return;
            }
            scroll = 0;
            x += details.focalPointDelta.dx;
            y += details.focalPointDelta.dy;
            final dx = x.truncate().clamp(-1000, 1000);
            final dy = y.truncate().clamp(-1000, 1000);
            if (dx != 0 || dy != 0) {
              widget.send({'type': 'mouse_move', 'dx': dx, 'dy': dy});
              x -= dx;
              y -= dy;
            }
          },
          onTap: () => widget.send({'type': 'mouse_click', 'button': 'left'}),
          onLongPress: () =>
              widget.send({'type': 'mouse_click', 'button': 'right'}),
          child: Container(
            height: 220,
            decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                borderRadius: BorderRadius.circular(20)),
            alignment: Alignment.center,
            child: const Text('터치패드\n두 손가락: 스크롤\n탭: 좌클릭 · 길게 누르기: 우클릭',
                textAlign: TextAlign.center),
          ),
        ),
      );
}
