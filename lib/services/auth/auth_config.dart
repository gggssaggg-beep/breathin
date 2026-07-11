/// Конфигурация Supabase-проекта «Дыши» (см. docs/SUPABASE_SETUP.md).
///
/// URL и anon-ключ НЕ секретны (данные защищает RLS на сервере — тот же
/// подход, что в Astra). Пока проект не создан владельцем, значения пустые —
/// [authConfigured] == false, и весь auth-слой выключен: приложение работает
/// в гостевом режиме без единого сетевого вызова.
library;

const String supabaseUrl = '';
const String supabaseAnonKey = '';

/// Deep link возврата из браузера после Google-входа.
/// Схема заведена в AndroidManifest (intent-filter) и Info.plist.
const String authRedirectUrl = 'dyshi://auth';

bool get authConfigured => supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
