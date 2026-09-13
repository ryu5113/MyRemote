import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myremote/screens/connected_screen.dart';
import 'package:myremote/services/websocket_service.dart';
import 'package:myremote/widgets/touchpad.dart';

void main() {
  testWidgets('connected controls do not contain a vertical page scroll',
      (tester) async {
    final remote = WebSocketService();
    addTearDown(remote.dispose);
    final text = TextEditingController();
    addTearDown(text.dispose);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: ConnectedScreen(remote: remote, message: text))));
    final scrollables = tester.widgetList<Scrollable>(find.byType(Scrollable));
    expect(scrollables.map((item) => item.axisDirection),
        everyElement(AxisDirection.right));
    expect(find.byType(Touchpad), findsOneWidget);
  });

  testWidgets('vertical finger movement remains on the touchpad',
      (tester) async {
    final remote = WebSocketService();
    addTearDown(remote.dispose);
    final text = TextEditingController();
    addTearDown(text.dispose);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: ConnectedScreen(remote: remote, message: text))));
    final gesture =
        await tester.startGesture(tester.getCenter(find.byType(Touchpad)));
    await gesture.moveBy(const Offset(0, 40));
    await tester.pump();
    await gesture.up();
    expect(remote.messages, isEmpty);
    expect(tester.takeException(), isNull);
  });
}
