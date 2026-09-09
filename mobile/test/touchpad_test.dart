import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myremote/widgets/touchpad.dart';

void main() {
  testWidgets('two fingers send scroll commands', (tester) async {
    final messages = <Map<String, dynamic>>[];
    await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: Touchpad(send: messages.add))));
    final center = tester.getCenter(find.byType(Touchpad));
    final first =
        await tester.startGesture(center - const Offset(30, 0), pointer: 1);
    final second =
        await tester.startGesture(center + const Offset(30, 0), pointer: 2);
    await first.moveBy(const Offset(0, 30));
    await second.moveBy(const Offset(0, 30));
    await tester.pump();
    await first.moveBy(const Offset(0, 20));
    await second.moveBy(const Offset(0, 20));
    await tester.pump();
    await first.up();
    await second.up();
    expect(messages.where((m) => m['type'] == 'mouse_scroll'), isNotEmpty);
  });

  testWidgets('tap and long press send distinct mouse buttons', (tester) async {
    final messages = <Map<String, dynamic>>[];
    await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: Touchpad(send: messages.add))));
    await tester.tap(find.byType(Touchpad));
    await tester.pump();
    expect(messages.last, {'type': 'mouse_click', 'button': 'left'});
    await tester.longPress(find.byType(Touchpad));
    await tester.pump();
    expect(messages.last, {'type': 'mouse_click', 'button': 'right'});
  });

  testWidgets('drag sends relative movement', (tester) async {
    final messages = <Map<String, dynamic>>[];
    await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: Touchpad(send: messages.add))));
    final gesture =
        await tester.startGesture(tester.getCenter(find.byType(Touchpad)));
    await gesture.moveBy(const Offset(40, 0));
    await tester.pump();
    await gesture.moveBy(const Offset(20, 5));
    await tester.pump();
    await gesture.up();
    expect(messages.where((m) => m['type'] == 'mouse_move'), isNotEmpty);
  });
}
