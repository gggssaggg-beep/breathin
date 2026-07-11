import 'package:flutter_test/flutter_test.dart';

import 'package:breathin/app/app.dart';

void main() {
  testWidgets('приложение стартует на главном экране «Breathe» (en)', (
    tester,
  ) async {
    await tester.pumpWidget(const BreathinApp());
    // AppLocalizations en → appTitle = 'Breathe'
    expect(find.text('Breathe'), findsOneWidget);
    // Одна из 12 карточек — квадратное дыхание
    expect(find.text('Box Breathing'), findsOneWidget);
  });

  testWidgets('на главном экране видны как минимум 4 карточки техник', (
    tester,
  ) async {
    await tester.pumpWidget(const BreathinApp());
    // GridView ленивый — проверяем несколько первых видимых карточек
    expect(find.text('Box Breathing'), findsOneWidget);
    expect(find.text('Triangle Breathing'), findsOneWidget);
    expect(find.text('4-7-8'), findsOneWidget);
    expect(find.text('4-2-4'), findsOneWidget);
  });

  testWidgets('переход в настройки открывает секцию обновлений', (
    tester,
  ) async {
    await tester.pumpWidget(const BreathinApp());
    // Кнопка настроек — BreathinIcon (свой набор), ищем по tooltip.
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    // На SettingsScreen должен быть текст «Автообновление» (русский hardcode)
    expect(find.text('Настройки'), findsWidgets);
    expect(find.text('Автообновление'), findsOneWidget);
  });
}
