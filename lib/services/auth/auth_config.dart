/// Конфигурация Supabase-проекта «Дыши» (см. docs/SUPABASE_SETUP.md).
///
/// URL и publishable-ключ НЕ секретны (данные защищает RLS на сервере — тот
/// же подход, что в Astra). Проект создан через Management API 2026-07-12:
/// ref `qfxghribrmeakxsexyjq`, регион eu-central-1 (Франкфурт), тариф Free.
library;

const String supabaseUrl = 'https://qfxghribrmeakxsexyjq.supabase.co';
const String supabaseAnonKey = 'sb_publishable_REG6n1i08LGRWDfCNTaYAg_EvhRElu-';

/// Deep link возврата из браузера после Google-входа.
/// Схема заведена в AndroidManifest (intent-filter), Info.plist и в
/// Redirect URLs проекта Supabase.
const String authRedirectUrl = 'dyshi://auth';

bool get authConfigured => supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

/// Google-провайдер включён в Supabase 2026-07-12 (Client ID/secret владельца
/// вписаны в конфиг проекта через Management API; docs/SUPABASE_SETUP.md §2
/// закрыт). Кнопки в UI: «Войти через Google» и «Привязать Google» для
/// гостевого профиля (identity linking, uid сохраняется).
const bool googleAuthEnabled = true;
