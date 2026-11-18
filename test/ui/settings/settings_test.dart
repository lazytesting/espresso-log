import 'package:espresso_log/domain/settings/settings_repository.dart';
import 'package:espresso_log/ui/components/section_header.dart';
import 'package:espresso_log/ui/settings/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../support/fake_settings.dart';

void main() {
  Future<void> pump(WidgetTester tester) => tester.pumpWidget(
    Provider<SettingsRepository>.value(
      value: FakeSettings()
        ..scaleSource = ScaleSource.decent
        ..pressureSource = PressureSource.bookoo,
      child: const MaterialApp(home: SettingsScreen()),
    ),
  );

  testWidgets('has a Settings title bar', (tester) async {
    await pump(tester);
    expect(find.widgetWithText(AppBar, 'Settings'), findsOneWidget);
  });

  testWidgets('uses shared section headers, scale first', (tester) async {
    await pump(tester);

    expect(find.byType(SectionHeader), findsNWidgets(3));
    final scale = find.widgetWithText(SectionHeader, 'Scale');
    final pressure = find.widgetWithText(SectionHeader, 'Pressure sensor');
    expect(scale, findsOneWidget);
    expect(pressure, findsOneWidget);
    expect(
      tester.getTopLeft(scale).dy,
      lessThan(tester.getTopLeft(pressure).dy),
    );
    expect(find.widgetWithText(SectionHeader, 'Developer tools'), findsOne);
  });

  testWidgets('device names use sentence case', (tester) async {
    await pump(tester);
    expect(find.text('Decent scale'), findsOneWidget);
    expect(find.text('Bookoo pressure sensor'), findsOneWidget);
  });

  testWidgets('Grinders tile navigates to the grinders route', (tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (context, state) => const SettingsScreen()),
        GoRoute(
          path: '/settings/grinders',
          builder: (context, state) => const Text('grinders page'),
        ),
      ],
    );
    await tester.pumpWidget(
      Provider<SettingsRepository>.value(
        value: FakeSettings(),
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.tap(find.text('Grinders'));
    await tester.pumpAndSettle();
    expect(find.text('grinders page'), findsOneWidget);
  });
}
