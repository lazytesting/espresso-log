import 'package:espresso_log/ui/components/bean_icon.dart';
import 'package:espresso_log/ui/scaffold/root_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('takes its size from the icon theme', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: IconTheme(
            data: IconThemeData(color: Colors.red, size: 24),
            child: BeanIcon(),
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byType(BeanIcon)), const Size(24, 24));
    expect(tester.takeException(), isNull);
  });

  testWidgets('is the Beans tab icon, selected and unselected', (tester) async {
    for (final index in [0, 2]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              currentIndex: index,
              items: rootNavItems,
            ),
          ),
        ),
      );

      expect(find.byType(BeanIcon), findsOneWidget);
      expect(find.text('Beans'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
}
