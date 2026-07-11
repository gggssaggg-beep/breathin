# Supabase для «Дыши» — что нужно сделать владельцу (один раз, ~15 минут)

Включает вход через Google (ТЗ §4). Код в приложении уже готов
(`lib/services/auth/`), от вас — только клики в двух консолях.
Процедура та же, что делалась для Astra (`C:\purba\astro_app\docs\SUPABASE_SETUP.md`),
отличаются только имена и deep link.

## 1. Проект Supabase (~5 мин)

1. **supabase.com** → Sign in (GitHub-аккаунт gggssaggg-beep).
2. **New project**: имя `dyshi`, пароль БД сгенерировать и СОХРАНИТЬ,
   регион `Central EU (Frankfurt)`, тариф Free.
3. **Project Settings → API** → скопировать и прислать в чат два значения
   (они НЕ секретные, пойдут в код):
   - `Project URL` (вида `https://xxxx.supabase.co`)
   - `anon public` / `publishable` ключ.

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
   добавить Callback URL из Supabase (**Authentication → Sign In / Up →
   Google**, вида `https://xxxx.supabase.co/auth/v1/callback`) → Create →
   получить Client ID + Client secret.
4. В Supabase **Authentication → Sign In / Up → Google**: включить тумблер,
   вставить Client ID и Client secret, Save.

## 3. URL приложения в Supabase (обязательно)

**Supabase → Authentication → URL Configuration → Redirect URLs** →
Add URL: `dyshi://auth` (deep link возврата в приложение; уже прописан в
AndroidManifest и Info.plist). Site URL можно не менять (веб-версии нет).

## 4. Прислать в чат

- Project URL + anon key (шаг 1.3);
- «Google включён» (шаг 2.4).

После этого Claude вписывает URL/ключ в `lib/services/auth/auth_config.dart`
— и кнопка «Войти через Google» в настройках оживает. Без этих значений
приложение работает как раньше (гостевой режим, ни одного сетевого вызова).

## Как устроен вход (справка)

Системный браузер (WebView Google не пускает — `disallowed_useragent`) →
OAuth у Google → Supabase → возврат в приложение deep link'ом `dyshi://auth`
с PKCE-кодом; `supabase_flutter` сам ловит ссылку и обменивает код на сессию.
SHA-1/keystore НЕ нужны (в отличие от Firebase/google_sign_in) — вход
заработает даже на debug-сборке.
