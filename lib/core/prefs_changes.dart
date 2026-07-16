/// Шина «настройки изменились»: data-сторы дёргают [notify] после записи,
/// облачный синк настроек ([PrefsSyncService]) подписывается в main().
/// Разрывает зависимость data → services; в тестах подписчика нет — no-op.
class PrefsChanges {
  PrefsChanges._();

  static void Function()? onChanged;

  static void notify() => onChanged?.call();
}
