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

/// Google-провайдер: станет true, когда владелец пришлёт Client ID/secret
/// из Google Cloud и провайдер будет включён в Supabase (docs/SUPABASE_SETUP.md
/// §2). До этого кнопка Google в UI скрыта — работает гостевой профиль
/// (анонимный вход, включён в проекте 2026-07-12).
const bool googleAuthEnabled = false;
