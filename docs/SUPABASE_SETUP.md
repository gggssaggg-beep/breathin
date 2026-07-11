# Supabase для «Дыши» — что нужно сделать владельцу (~10 минут)

Включает вход через Google (ТЗ §4). Код в приложении уже готов
(`lib/services/auth/`). Процедура та же, что делалась для Astra
(`C:\purba\astro_app\docs\SUPABASE_SETUP.md`), но Supabase-часть уже
СДЕЛАНА Claude через Management API (2026-07-12, по Personal Access Token
владельца) — остался только Google (раздел 2).

## 1. Проект Supabase — ✅ СДЕЛАНО (Management API)

- Проект `dyshi`, ref `qfxghribrmeakxsexyjq`, регион Frankfurt, тариф Free.
- `Project URL` и publishable-ключ вписаны в `lib/services/auth/auth_config.dart`.
- Redirect URL `dyshi://auth` прописан (раздел 3 тоже закрыт).
- Пароль БД сгенерирован и передан владельцу в чате — сохранить; при утере
  сбрасывается через Dashboard → Project Settings → Database.

## 2. Google-вход (~10 мин)

1. **console.cloud.google.com** → New Project → имя `dyshi`.
   (Отдельный проект, а не Astra: имя приложения на экране согласия Google
   видят пользователи — должно быть «Дыши», не «Astra».)
2. **APIs & Services → OAuth consent screen**: тип External, имя `Дыши`,
   свой e-mail → Save. Затем **PUBLISH APP** (In production) — иначе входить
   смогут только e-mail'ы из списка Test users. Верификация Google для
   базовых данных (e-mail/профиль) не требуется; предупреждение «Google не
   проверил…» у новых пользователей — нормально (Дополнительно → Перейти).
3. **Credentials → Create Credentials → OAuth client ID**: тип **Web
   application**, имя `Dyshi Supabase`; в **Authorized redirect URIs**
   добавить ровно эту строку:

   `https://qfxghribrmeakxsexyjq.supabase.co/auth/v1/callback`

   → Create → показать **Client ID** и **Client secret**.
4. **Прислать Client ID и Client secret в чат** — Claude включит
   Google-провайдер в Supabase через API. (Либо самостоятельно: Supabase →
   Authentication → Sign In / Up → Google → тумблер + вставить оба значения.)

## 2b. Гостевой профиль — ✅ СДЕЛАНО (работает без Google)

Анонимный вход (`external_anonymous_users_enabled`) включён через API
2026-07-12: кнопка «Создать профиль (без регистрации)» в настройках даёт
аккаунт для челленджей без почты и консолей. Google-вход останется
дополнительной опцией — после раздела 2 переключить
`googleAuthEnabled = true` в `lib/services/auth/auth_config.dart`.
Ограничение гостевого профиля: живёт в приложении на одном устройстве,
при выходе/переустановке не восстанавливается (позже привяжем Google
через identity linking).

## 3. URL приложения в Supabase — ✅ СДЕЛАНО

`dyshi://auth` уже в Redirect URLs (и в Site URL); в приложении deep link
прописан в AndroidManifest и Info.plist.

## Примечание про имя «Дыши»

Пользователь видит имя приложения в двух местах: на лаунчере телефона
(«Дыши» — уже прописано в Android label и CFBundleDisplayName) и на экране
Google-входа (берётся из **App name** consent screen — шаг 2.2, задать
`Дыши`). Мелкая строка «to continue to qfxghribrmeakxsexyjq.supabase.co»
на Google-экране остаётся — убирается только платным custom domain
Supabase, для нашего масштаба не требуется.

## Как устроен вход (справка)

Системный браузер (WebView Google не пускает — `disallowed_useragent`) →
OAuth у Google → Supabase → возврат в приложение deep link'ом `dyshi://auth`
с PKCE-кодом; `supabase_flutter` сам ловит ссылку и обменивает код на сессию.
SHA-1/keystore НЕ нужны (в отличие от Firebase/google_sign_in) — вход
заработает даже на debug-сборке.
