/// Конфигурация Supabase-проекта «Дыши» (см. docs/SUPABASE_SETUP.md).
///
/// URL и publishable-ключ НЕ секретны (данные защищает RLS на сервере — тот
/// же подход, что в Astra). Проект создан через Management API 2026-07-12:
/// ref `qfxghribrmeakxsexyjq`, регион eu-central-1 (Франкфурт), тариф Free.
library;

import 'package:flutter/foundation.dart' show kIsWeb;

const String supabaseUrl = 'https://qfxghribrmeakxsexyjq.supabase.co';
const String supabaseAnonKey = 'sb_publishable_REG6n1i08LGRWDfCNTaYAg_EvhRElu-';

/// Возврат из браузера после Google-входа.
/// Мобилки — deep link (схема в AndroidManifest, Info.plist и Redirect URLs
/// Supabase); веб/PWA — текущий адрес страницы (origin+path без query/fragment:
/// в query живёт ?code=, который нельзя занести в whitelist; адрес GitHub
/// Pages добавить в Redirect URLs — docs/SUPABASE_SETUP.md).
String get authRedirectUrl => kIsWeb
    ? Uri.base.replace(query: '', fragment: '').toString()
    : 'dyshi://auth';

bool get authConfigured => supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

/// Google-провайдер включён в Supabase 2026-07-12 (Client ID/secret владельца
/// вписаны в конфиг проекта через Management API; docs/SUPABASE_SETUP.md §2
/// закрыт). Кнопки в UI: «Войти через Google» и «Привязать Google» для
/// гостевого профиля (identity linking, uid сохраняется).
const bool googleAuthEnabled = true;

/// E-mail-вход (magic-link) через Supabase Auth. Провайдер `email` включён
/// в проекте по умолчанию (проверено 2026-07-15 через /auth/v1/settings:
/// "email": true, disable_signup: false), redirect `dyshi://auth` уже в
/// whitelist — доп. настройка панели не требуется. Письмо со ссылкой шлёт
/// встроенный SMTP Supabase (лимит несколько писем/час — для личного
/// использования достаточно; свой SMTP — при росте, docs/SUPABASE_SETUP.md).
const bool emailAuthEnabled = true;
