import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:breathin/features/onboarding/coach_controller.dart';
import 'package:breathin/features/onboarding/coach_mark.dart';
import 'package:breathin/l10n/generated/app_localizations.dart';
import 'package:breathin/services/onboarding/coach_store.dart';

/// Оборачивает виджет в MaterialApp с локализацией (en) и CoachScope.
Widget _wrap(Widget child, CoachController controller) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: CoachScope(
      controller: controller,
      child: Scaffold(body: child),
    ),
  );
}

/// Инициализирует CoachController с реальным CoachStore поверх моков.
Future<CoachController> _makeController() async {
  final controller = CoachController(store: CoachStore());
  await controller.init();
  return controller;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('CoachMark', () {
    testWidgets(
        'при пустом seen показывает сообщение после первого кадра',
        (tester) async {
      final controller = await _makeController();

      await tester.pumpWidget(
        _wrap(
          const CoachMark(id: 'test.id', message: 'Test hint message'),
          controller,
        ),
      );
      // Запускаем postFrameCallback и анимацию появления
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Test hint message'), findsOneWidget);
      // Кнопка «Got it ✕» (en)
      expect(find.textContaining('Got it'), findsOneWidget);
    });

    testWidgets('тап по пузырьку скрывает подсказку', (tester) async {
      final controller = await _makeController();

      await tester.pumpWidget(
        _wrap(
          const CoachMark(id: 'test.dismiss', message: 'Dismiss me'),
          controller,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Подсказка видна
      expect(find.text('Dismiss me'), findsOneWidget);

      // Тапаем по пузырьку
      await tester.tap(find.text('Dismiss me'));
      // Ждём анимацию закрытия и уведомление контроллера
      await tester.pumpAndSettle();

      // Подсказка исчезла
      expect(find.text('Dismiss me'), findsNothing);
      // Контроллер обновил seen
      expect(controller.shouldShow('test.dismiss'), isFalse);
    });

    testWidgets('когда id уже в seen — подсказка не показывается',
        (tester) async {
      // Предзаполняем seen через store до создания контроллера
      final store = CoachStore();
      await store.markSeen('already.seen');
      final controller = CoachController(store: store);
      await controller.init();

      final childKey = GlobalKey();
      await tester.pumpWidget(
        _wrap(
          CoachMark(
            id: 'already.seen',
            message: 'Should not appear',
            child: Text('child widget', key: childKey),
          ),
          controller,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Текст подсказки не виден
      expect(find.text('Should not appear'), findsNothing);
      // Child — виден
      expect(find.text('child widget'), findsOneWidget);
    });

    testWidgets('когда id не в seen и child задан — показывает оба',
        (tester) async {
      final controller = await _makeController();

      await tester.pumpWidget(
        _wrap(
          const CoachMark(
            id: 'test.with.child',
            message: 'Hint with child',
            child: Text('Below hint'),
          ),
          controller,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Hint with child'), findsOneWidget);
      expect(find.text('Below hint'), findsOneWidget);
    });
  });
}
