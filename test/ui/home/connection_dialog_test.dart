import 'package:espresso_log/ui/home/device_connection/connection_modal_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, {required bool paused}) =>
    tester.pumpWidget(
      MaterialApp(home: Scaffold(body: ConnectionDialog(paused: paused))),
    );

void main() {
  testWidgets('connecting shows a spinner and what it connects to', (
    tester,
  ) async {
    await _pump(tester, paused: false);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(
      find.text('Connecting to your scale and pressure sensor'),
      findsOneWidget,
    );
  });

  testWidgets('paused explains why and how to resume', (tester) async {
    await _pump(tester, paused: true);

    expect(find.text('Devices paused to save battery'), findsOneWidget);
    expect(find.text('Touch the screen to reconnect'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
