-- Схема Supabase «Дыши» v1: профили + челленджи по коду-приглашению.
-- Применена к проекту qfxghribrmeakxsexyjq через Management API 2026-07-12.
-- Воспроизводимость: файл — источник правды; изменения — новыми
-- идемпотентными блоками (create ... if not exists / or replace).

-- Профили: публичное имя для отображения в челленджах. Заполняется
-- триггером из Google-метаданных при первом входе.
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default 'Без имени',
  created_at timestamptz not null default now()
);
alter table public.profiles enable row level security;

drop policy if exists "profiles readable by authenticated" on public.profiles;
create policy "profiles readable by authenticated" on public.profiles
  for select to authenticated using (true);

drop policy if exists "profiles update own" on public.profiles;
create policy "profiles update own" on public.profiles
  for update to authenticated
  using (auth.uid() = id) with check (auth.uid() = id);

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, display_name)
  values (
    new.id,
    coalesce(
      new.raw_user_meta_data->>'full_name',
      new.raw_user_meta_data->>'name',
      split_part(coalesce(new.email, 'user'), '@', 1)
    )
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Челленджи: соревнование по коду-приглашению (без системы друзей в v1 —
-- код случайный, ввод кода = согласие участвовать).
create table if not exists public.challenges (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  title text not null,
  metric text not null check (metric in ('sessions', 'minutes', 'streak')),
  target int not null check (target > 0),
  starts_on date not null,
  ends_on date not null check (ends_on >= starts_on),
  creator uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);
alter table public.challenges enable row level security;

-- select всем вошедшим: нужен для присоединения по коду; код — случайные
-- 6 символов, содержимое челленджа не чувствительно.
drop policy if exists "challenges readable by authenticated" on public.challenges;
create policy "challenges readable by authenticated" on public.challenges
  for select to authenticated using (true);

drop policy if exists "challenges insert own" on public.challenges;
create policy "challenges insert own" on public.challenges
  for insert to authenticated with check (auth.uid() = creator);

create table if not exists public.challenge_participants (
  challenge_id uuid not null references public.challenges(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  progress int not null default 0,
  updated_at timestamptz not null default now(),
  primary key (challenge_id, user_id)
);
alter table public.challenge_participants enable row level security;

-- Самоссылка в политике на ту же таблицу даёт рекурсию RLS —
-- обходим security definer-функцией (стандартный паттерн).
create or replace function public.is_challenge_participant(ch uuid)
returns boolean
language sql
security definer set search_path = public
stable
as $$
  select exists (
    select 1 from challenge_participants
    where challenge_id = ch and user_id = auth.uid()
  );
$$;

drop policy if exists "participants readable by co-participants"
  on public.challenge_participants;
create policy "participants readable by co-participants"
  on public.challenge_participants
  for select to authenticated
  using (public.is_challenge_participant(challenge_id));

drop policy if exists "participants join self" on public.challenge_participants;
create policy "participants join self" on public.challenge_participants
  for insert to authenticated with check (auth.uid() = user_id);

drop policy if exists "participants update own progress"
  on public.challenge_participants;
create policy "participants update own progress"
  on public.challenge_participants
  for update to authenticated
  using (auth.uid() = user_id) with check (auth.uid() = user_id);
