import 'package:flutter_test/flutter_test.dart';

import 'package:breathin/app/app.dart';

void main() {
  testWidgets('приложение стартует на главном экране «Breathe» (en)', (
    tester,
  ) async {
    // checkUpdates: false — тест не должен зависеть от сетевого пути OTA
    // (сейчас его гасило лишь отсутствие PackageInfo-мока — хрупко, ревью П2).
    await tester.pumpWidget(const BreathinApp(checkUpdates: false));
    // AppLocalizations en → appTitle = 'Breathe'
    expect(find.text('Breathe'), findsOneWidget);
    // Одна из 12 карточек — квадратное дыхание
    expect(find.text('Box Breathing'), findsOneWidget);
  });

  testWidgets('на главном экране видны как минимум 4 карточки техник', (
    tester,
  ) async {
    // checkUpdates: false — тест не должен зависеть от сетевого пути OTA
    // (сейчас его гасило лишь отсутствие PackageInfo-мока — хрупко, ревью П2).
    await tester.pumpWidget(const BreathinApp(checkUpdates: false));
    // GridView ленивый — проверяем несколько первых видимых карточек
    expect(find.text('Box Breathing'), findsOneWidget);
    expect(find.text('Triangle Breathing'), findsOneWidget);
    expect(find.text('4-7-8'), findsOneWidget);
    expect(find.text('4-2-4'), findsOneWidget);
  });

  testWidgets('переход в настройки открывает секцию обновлений', (
    tester,
  ) async {
    // checkUpdates: false — тест не должен зависеть от сетевого пути OTA
    // (сейчас его гасило лишь отсутствие PackageInfo-мока — хрупко, ревью П2).
    await tester.pumpWidget(const BreathinApp(checkUpdates: false));
    // Кнопка настроек — BreathinIcon (свой набор), ищем по tooltip.
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    // На SettingsScreen — локализованные строки (тесты идут в en-локали)
    expect(find.text('Settings'), findsWidgets);
    expect(find.text('Auto-update'), findsOneWidget);
  });
}
