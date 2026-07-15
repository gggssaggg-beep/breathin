import 'package:flutter/material.dart';

import '../../services/onboarding/coach_store.dart';

/// Контроллер обучалок — ChangeNotifier поверх [CoachStore].
///
/// Хранит кешированный набор закрытых id и флаг готовности (данные загружены).
/// [shouldShow] безопасно возвращает false до завершения загрузки.
class CoachController extends ChangeNotifier {
  final CoachStore _store;

  Set<String> _seen = {};
  bool _ready = false;

  CoachController({CoachStore? store}) : _store = store ?? CoachStore();

  /// true — данные загружены из хранилища и можно показывать подсказки.
  bool get isReady => _ready;

  /// Загружает сохранённые id. Вызывать один раз после создания контроллера.
  Future<void> init() async {
    _seen = await _store.loadSeen();
    _ready = true;
    notifyListeners();
  }

  /// Нужно ли показывать подсказку с данным [id].
  bool shouldShow(String id) => _ready && !_seen.contains(id);

  /// Закрывает подсказку [id]: добавляет в seen, персистит, уведомляет.
  Future<void> dismiss(String id) async {
    if (_seen.contains(id)) return;
    _seen = {..._seen, id};
    notifyListeners();
    await _store.markSeen(id);
  }

  /// Сбрасывает все подсказки и приветствие — покажутся заново.
  Future<void> resetAll() async {
    await _store.reset();
    _seen = {};
    notifyListeners();
  }
}

/// InheritedNotifier, который предоставляет [CoachController] вниз по дереву.
///
/// Оборачивает всё приложение в app.dart:
/// ```dart
/// CoachScope(controller: _coachController, child: MaterialApp(...))
/// ```
/// Доступ: `CoachScope.of(context)`.
class CoachScope extends InheritedNotifier<CoachController> {
  const CoachScope({
    super.key,
    required CoachController controller,
    required super.child,
  }) : super(notifier: controller);

  /// Возвращает ближайший [CoachController] из контекста.
  static CoachController of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<CoachScope>();
    assert(scope != null, 'CoachScope не найден в дереве виджетов');
    return scope!.notifier!;
  }
}
