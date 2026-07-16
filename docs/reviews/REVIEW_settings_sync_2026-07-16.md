# Ревью PR #70 — синк настроек (feat/settings-sync)

Дата: 2026-07-16  
Ревьюер: Claude Fable 5  
Файлы: `lib/services/sync/prefs_sync_service.dart`, `lib/core/prefs_changes.dart`,
хуки `PrefsChanges.notify()` в сторах, `lib/main.dart`, `docs/supabase/schema.sql`,
`test/services/prefs_sync_test.dart`.

---

## Сводная таблица

| № | Важность  | Файл:строка | Суть |
|---|-----------|-------------|------|
| 1 | **критично** | `main.dart:27-36` / `prefs_sync_service.dart:165-169` | Гонка: дебаунс-пуш vs `syncNow` — login-событие не отменяет pending дебаунс |
| 2 | **критично** | `main.dart:30,36` | Гонка logout→login: `onSignedOut()` и `syncNow()` — оба `unawaited`, маркер прошлого аккаунта может попасть в `syncNow` нового |
| 3 | **серьёзно** | `prefs_sync_service.dart:165-170` | Гостевые изменения молча теряются при входе — маркер не ставится без авторизации |
| 4 | **серьёзно** | `prefs_sync_service.dart:154,156` | `instance` не final, `_cloudHasTable` статична — потенциал «навсегда отключить синк» при замене инстанса |
| 5 | **мелочь**  | `prefs_sync_service.dart:380-384` | LWW: равные timestamps → `none`, но при рассинхроне часов возможна вечная «тихая несинхронность» |

---

## Проверенные сценарии без находок

- Полнота белого списка ключей: все ключи из `lib/` (9 синкуемых, 5 несинкуемых) проверены
  вручную; онбординг (`onboarding.*`), разрешения (`notification_permission.asked`),
  обновления (`update.*`), маркер (`prefs_sync.updated_at`), UI-хинт (`stats.guest_hint*`)
  правильно не включены.
- Типы jsonb при восстановлении: `favorites.v1` хранится как `List<String>` в prefs,
  уходит как JSON-массив в jsonb, возвращается как `List<dynamic>` — `l.cast<String>()`
  корректен. `bolt_log.v1` — строка в prefs, строка в jsonb, строка обратно — `as String?`
  корректен. `bool`, `int`, `double`, `String` — switch-case покрывает все варианты.
- Слияние BOLT-журналов: union по id, сортировка по takenAt — алгоритм правильный.
- RLS: политика `user_prefs own all` с `auth.uid() = user_id` — корректна.
- `_cloudHasTable = false` при `PGRST205`/`42P01` — правильные коды PostgREST/PostgreSQL.
- `applyPrefsSnapshot`: удаление ключей, которых нет в облаке — перенос reset-техники
  с другого устройства работает правильно.
- BOLT: если в remote нет ключа `bolt_log.v1`, локальный журнал не стирается, и он
  допушивается (boltGrew = true) — корректно.

---

## Находки (подробно)

---

### №1 КРИТИЧНО — Гонка: дебаунс-пуш vs `syncNow` при логине

**Файл:строка:**
- `lib/main.dart:36` — `unawaited(PrefsSyncService.instance.syncNow())`
- `lib/services/sync/prefs_sync_service.dart:165-169` — `onLocalChange` / дебаунс

**Сценарий отказа:**

1. Пользователь вошёл, менял настройки → дебаунс-таймер запустился (2 сек).
2. Выход → вход другого аккаунта или re-login (например, возврат из Google-браузера).
3. Срабатывает `syncNow()` (unawaited) — начинает сетевой запрос (1–3 сек).
4. **Дебаунс-таймер срабатывает** (~2 сек) → `push()` стартует параллельно:
   читает локальный снапшот (может быть устаревшим), пишет в облако с маркером «старой»
   локальной записи.
5. `syncNow()` завершает `applyPrefsSnapshot` — применяет облачные данные локально,
   маркер обновляется до `remoteTs`.
6. Итог: Cloud теперь содержит локальные данные из п.4 (от push), а локальные данные — 
   из п.5 (из облака). Они расходятся. На следующем входе цикл повторяется.

**Предлагаемый фикс:**

В начале `syncNow()` отменять дебаунс:

```dart
Future<void> syncNow() async {
  _debounce?.cancel();
  _debounce = null;
  final user = auth.currentUser;
  ...
}
```

---

### №2 КРИТИЧНО — Гонка logout→login: cross-account утечка маркера

**Файл:строка:**
- `lib/main.dart:30` — `unawaited(PrefsSyncService.instance.onSignedOut())`
- `lib/main.dart:36` — `unawaited(PrefsSyncService.instance.syncNow())`
- `lib/services/sync/prefs_sync_service.dart:174-180` — `onSignedOut`

**Сценарий отказа:**

1. Пользователь A выходит. Auth-стрим получает событие `null` →
   `unawaited(onSignedOut())` запускается, но не ждётся.
2. **Немедленно** (до того, как `onSignedOut()` успела удалить маркер из prefs)
   приходит событие нового входа пользователя B (или возврат из Google-deeplink).
3. `unawaited(syncNow())` стартует и читает маркер — **маркер ещё аккаунта A** (не удалён).
4. `decidePrefsSync(localChangedAt: A_marker, remoteUpdatedAt: B_remote_ts)`:
   если A изменял настройки недавно, `localChangedAt > remoteUpdatedAt` → `pushLocal`.
5. Настройки аккаунта A пишутся в облако аккаунта B.

Практически воспроизводится при «выход → быстрый вход» (Google OAuth — открывает браузер
и сразу делает deep link обратно).

**Предлагаемый фикс:**

В `main.dart` дождаться `onSignedOut` перед `syncNow`:

```dart
const AuthService().onAuthStateChange.listen((user) async {
  if (user == null) {
    syncedUid = null;
    await PrefsSyncService.instance.onSignedOut(); // await, не unawaited
    return;
  }
  ...
});
```

Альтернатива: `syncNow()` сравнивает `user.id` с `auth.currentUser?.id` в начале и
прерывается, если они расходятся (маркер принадлежит другому аккаунту). Но проще всего
ждать `onSignedOut`.

---

### №3 СЕРЬЁЗНО — Гостевые изменения молча теряются при первом входе

**Файл:строка:**
- `lib/services/sync/prefs_sync_service.dart:165-170` — `onLocalChange`

**Сценарий отказа:**

1. Пользователь установил приложение, не вошёл (гость).
2. Настроил несколько техник, выбрал звук, язык (все сторы вызывают `notify()`).
3. `onLocalChange()` проверяет `auth.currentUser == null` → возвращается, **маркер не ставится**.
4. Пользователь входит в аккаунт → `syncNow()` →
   `decidePrefsSync(localChangedAt: null, remoteUpdatedAt: <облако>)` → `applyRemote`.
5. Все локальные настройки гостя **перезаписаны** облачными без предупреждения.

Это поведение описано в комментарии («Гость не пушит — его правки при входе проиграют
облаку»), но оно влечёт неожиданную потерю данных при обычном сценарии «настроил — вошёл».

**Предлагаемый фикс:**

Ставить маркер даже для гостя (только маркер, не push):

```dart
void onLocalChange() {
  unawaited(_touchMarker()); // убрать guard по currentUser здесь
  if (auth.currentUser == null) return; // дебаунс-push — только авторизованным
  _debounce?.cancel();
  _debounce = Timer(const Duration(seconds: 2), () => unawaited(push()));
}
```

Тогда при входе `localChangedAt != null` → LWW честно сравнивает времена. Если настройки
гостя свежее облака → локальное побеждает. Дополнительно обновить тест
«без входа onLocalChange/syncNow — тихий no-op»: маркер теперь будет выставляться.

---

### №4 СЕРЬЁЗНО — `instance` не final; `_cloudHasTable` статична

**Файл:строка:**
- `lib/services/sync/prefs_sync_service.dart:154` — `static PrefsSyncService instance = PrefsSyncService()`
- `lib/services/sync/prefs_sync_service.dart:156` — `static bool _cloudHasTable = true`

**Сценарий отказа:**

1. Таблица `user_prefs` временно отсутствует в базе (миграция ещё не применена).
2. `syncNow()` / `push()` получают `PGRST205` → `_cloudHasTable = false`.
3. Владелица применяет миграцию, перезапускает приложение — `_cloudHasTable = false`
   **сбрасывается** (статика живёт только в процессе). Здесь проблемы нет.
4. Но: `_debounce` — инстанс-поле. Если тест или код заменит `PrefsSyncService.instance`
   на новый объект (`instance = PrefsSyncService()`), активный дебаунс-таймер старого
   объекта **не отменяется**: продолжит висеть в памяти и сработает, вызвав `push()` на
   устаревшем инстансе.

**Предлагаемый фикс:**

Объявить `instance` финальным (`static final`) и не давать его переназначать.
В тестах создавать отдельный инстанс для проверок, а не подменять синглтон.

---

### №5 МЕЛОЧЬ — LWW при рассинхроне часов: «вечная тихая несинхронность»

**Файл:строка:**
- `lib/services/sync/prefs_sync_service.dart:83-92` — `decidePrefsSync`

**Сценарий:**

Устройство A с часами +5 минут пушит настройки. Устройство B с правильными часами
читает `remoteUpdatedAt` (от A) как «в будущем». `localChangedAt < remoteUpdatedAt` →
`applyRemote`. Устройство B применяет настройки A. Затем B меняет настройки:
`localChangedAt` = сейчас (правильное время) < `remoteUpdatedAt` (от A +5 мин) → снова
`applyRemote`. **Все изменения на B молча перезаписываются** пока часы A не синхронизируются.

Равные timestamps (`none`) — при правильных часах почти никогда не случается, баг
несущественный. Рассинхрон часов — реальный кейс на Android без интернет-времени.

**Предлагаемый фикс:**

Минимальный: в `decidePrefsSync` считать «локальное свежее», если разница < N секунд
(например, 5 сек) — нейтрализует мелкие рассинхроны. Полный: добавить server-side
timestamp из ответа Supabase (`now()` на сервере) вместо клиентского `DateTime.now()`.
Для v1 допустимо оставить как есть, задокументировав ограничение.

---

## Решения по находкам (Fable, 2026-07-16, коммит с фиксами в этой же ветке)

| № | Решение |
|---|---------|
| 1 | **ИСПРАВЛЕНО**: `syncNow()` первым делом гасит взведённый дебаунс (`_debounce?.cancel()`). Локальные правки не теряются — их маркер новее облака, решение LWW будет `pushLocal`. |
| 2 | **ИСПРАВЛЕНО**: `onSignedOut()` сохраняет future сброса маркера в `_signOutFlush`; `push()` и `syncNow()` дожидаются его перед чтением маркера — маркер прежнего аккаунта не утечёт в облако нового. |
| 3 | **ОТКЛОНЕНО (осознанный компромисс)**: если гостевой маркер ставить всегда, при входе победит гость, а его снапшот НЕПОЛОН — push удалил бы в облаке все настройки, которых у гостя нет (applyPrefsSnapshot на другом устройстве сотрёт их локально). Потеря пары гостевых правок при входе — меньшее зло, чем стирание всего облачного документа. Семантика «вход → настройки вернулись» задокументирована в onLocalChange. |
| 4 | **ИСПРАВЛЕНО**: `instance` теперь `static final`. |
| 5 | **ПРИНЯТО КАК ОГРАНИЧЕНИЕ**: клиентские часы — задокументировано в doc-комментарии сервиса; для одного пользователя с 1–2 устройствами приемлемо, серверное время потребовало бы RPC. |
