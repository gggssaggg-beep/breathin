import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:breathin/app/app.dart';

void main() {
  testWidgets('приложение стартует на главном экране «Дыши»', (tester) async {
    await tester.pumpWidget(const BreathinApp());
    expect(find.text('Дыши'), findsOneWidget);
    expect(find.text('Квадратное дыхание'), findsOneWidget);
  });

  testWidgets('переход в настройки открывает секцию обновлений',
      (tester) async {
    await tester.pumpWidget(const BreathinApp());
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Настройки'), findsOneWidget);
    expect(find.text('Автообновление'), findsOneWidget);
  });
}
