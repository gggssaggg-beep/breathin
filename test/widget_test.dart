import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:breathin/app/app.dart';

void main() {
  testWidgets(
      'регресс: карточка Вима Хофа не переполняется при крупном шрифте', (
    tester,
  ) async {
    // Отзыв 2026-07-15: «BOTTOM OVERFLOWED BY 7 PIXELS» на карточке
    // «Метод Вима Хофа» — двухстрочное название + солнышко не влезали в
    // квадратную ячейку грида при крупном системном шрифте. Переполнение
    // в тесте падает само (FlutterError), отдельных expect не нужно.
    tester.view.physicalSize = const Size(1080, 2280); // типовой телефон
    tester.view.devicePixelRatio = 3.0; // логически 360×760
    tester.platformDispatcher.textScaleFactorTestValue = 1.4;
    addTearDown(() {
      tester.view.reset();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });
    await tester.pumpWidget(
      const BreathinApp(checkUpdates: false, showOnboarding: false),
    );
    // Карточка 11-я — доскролливаем ленивый грид до её построения.
    await tester.scrollUntilVisible(
      find.text('Wim Hof Method'),
      200,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('Wim Hof Method'), findsOneWidget);
  });

  testWidgets('приложение стартует на главном экране «Breathe» (en)', (
    tester,
  ) async {
    // checkUpdates: false, showOnboarding: false — тест не зависит от сети
    // и приветственного диалога (SharedPreferences mock не нужен).
    await tester.pumpWidget(
      const BreathinApp(checkUpdates: false, showOnboarding: false),
    );
    // AppLocalizations en → appTitle = 'Breathe'
    expect(find.text('Breathe'), findsOneWidget);
    // Одна из 12 карточек — квадратное дыхание
    expect(find.text('Box Breathing'), findsOneWidget);
  });

  testWidgets('на главном экране видны как минимум 4 карточки техник', (
    tester,
  ) async {
    // checkUpdates: false, showOnboarding: false — тест не зависит от сети
    // и приветственного диалога.
    await tester.pumpWidget(
      const BreathinApp(checkUpdates: false, showOnboarding: false),
    );
    // GridView ленивый — проверяем несколько первых видимых карточек
    expect(find.text('Box Breathing'), findsOneWidget);
    expect(find.text('Triangle Breathing'), findsOneWidget);
    expect(find.text('4-7-8'), findsOneWidget);
    expect(find.text('4-2-4'), findsOneWidget);
  });

  testWidgets('переход в настройки открывает секцию обновлений', (
    tester,
  ) async {
    // checkUpdates: false, showOnboarding: false — тест не зависит от сети
    // и приветственного диалога.
    await tester.pumpWidget(
      const BreathinApp(checkUpdates: false, showOnboarding: false),
    );
    // Кнопка настроек — BreathinIcon (свой набор), ищем по tooltip.
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    // На SettingsScreen — локализованные строки (тесты идут в en-локали)
    expect(find.text('Settings'), findsWidgets);
    expect(find.text('Auto-update'), findsOneWidget);
  });
}
