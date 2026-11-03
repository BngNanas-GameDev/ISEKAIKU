-- Isekaiku — skema awal Supabase
-- Jalankan di Supabase Dashboard → SQL Editor.
--
-- Prinsip:
-- - Media (gambar manga) TIDAK disimpan di sini; hanya teks.
-- - Aplikasi tetap local-first. Tabel ini untuk sinkronisasi & komunitas.
-- - Semua tabel milik pengguna memakai RLS ketat (user_id = auth.uid()).

-- ---------------------------------------------------------------------------
-- Profil
-- ---------------------------------------------------------------------------
create table if not exists public.profiles (
  id         uuid primary key references auth.users (id) on delete cascade,
  username   text unique,
  created_at timestamptz not null default now()
);

-- Buat baris profil otomatis saat user baru mendaftar.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, username)
  values (
    new.id,
    -- default: bagian sebelum @ dari email, ditambah 4 karakter id agar unik
    coalesce(
      split_part(coalesce(new.email, 'user'), '@', 1)
        || '_' || substr(new.id::text, 1, 4),
      'user_' || substr(new.id::text, 1, 4)
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

-- ---------------------------------------------------------------------------
-- Pustaka: manga diikuti
-- ---------------------------------------------------------------------------
create table if not exists public.library_entries (
  user_id     uuid not null references auth.users (id) on delete cascade,
  manga_id    text not null,
  title       text not null,
  cover_url   text,
  author      text,
  followed_at timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  primary key (user_id, manga_id)
);

-- ---------------------------------------------------------------------------
-- Progres baca (satu baris per manga)
-- ---------------------------------------------------------------------------
create table if not exists public.reading_progress (
  user_id        uuid not null references auth.users (id) on delete cascade,
  manga_id       text not null,
  manga_title    text,
  cover_url      text,
  chapter_id     text not null,
  chapter_number text,
  chapter_title  text,
  page           int not null default 0 check (page >= 0),
  total_pages    int not null default 0 check (total_pages >= 0),
  read_at        timestamptz not null default now(),
  updated_at     timestamptz not null default now(),
  primary key (user_id, manga_id)
);

-- ---------------------------------------------------------------------------
-- Chapter yang sudah dibaca
-- ---------------------------------------------------------------------------
create table if not exists public.read_chapters (
  user_id    uuid not null references auth.users (id) on delete cascade,
  manga_id   text not null,
  chapter_id text not null,
  read_at    timestamptz not null default now(),
  primary key (user_id, manga_id, chapter_id)
);

-- ---------------------------------------------------------------------------
-- Komentar
-- ---------------------------------------------------------------------------
create table if not exists public.comments (
  id            uuid primary key default gen_random_uuid(),
  manga_id      text not null,
  chapter_id    text,
  user_id       uuid not null references auth.users (id) on delete cascade,
  body          text not null check (char_length(body) between 1 and 1000),
  created_at    timestamptz not null default now(),
  is_hidden     boolean not null default false,
  hidden_reason text
);

create index if not exists comments_manga_created_idx
  on public.comments (manga_id, created_at desc);

-- Moderasi sisi server: padanan aturan di lib/core/moderation.
-- Klien melakukan normalisasi lebih kaya (leetspeak, spasi), ini lapisan
-- terakhir supaya klien yang dimodifikasi tetap tidak bisa menembus.
create or replace function public.comments_moderate()
returns trigger
language plpgsql
as $$
declare body_lower text;
begin
  body_lower := lower(new.body);

  if body_lower ~ '(https?://|hxxps?://|www\.|t\.me/|wa\.me/|bit\.ly/|linktr\.ee/|discord\.gg/|\[\.\]|\(\.\))' then
    raise exception 'Tautan eksternal tidak diizinkan'
      using errcode = 'check_violation';
  end if;

  if body_lower ~ '(judol|judi|slot|gacor|maxwin|scatter|togel|bandar|sbobet|pragmatic|rtp|deposit|taruhan|betting|parlay|jackpot)' then
    raise exception 'Konten terkait judi online dilarang'
      using errcode = 'check_violation';
  end if;

  if body_lower ~ '(narkoba|narkotika|sabu|shabu|ganja|marijuana|kanabis|cannabis|ekstasi|heroin|kokain|cocaine|morfin|opium|psikotropika)' then
    raise exception 'Konten terkait narkoba dilarang'
      using errcode = 'check_violation';
  end if;

  return new;
end;
$$;

drop trigger if exists comments_moderate_trigger on public.comments;
create trigger comments_moderate_trigger
  before insert or update of body on public.comments
  for each row execute function public.comments_moderate();

-- ---------------------------------------------------------------------------
-- Laporan komentar
-- ---------------------------------------------------------------------------
create table if not exists public.comment_reports (
  id          uuid primary key default gen_random_uuid(),
  comment_id  uuid not null references public.comments (id) on delete cascade,
  reporter_id uuid not null references auth.users (id) on delete cascade,
  reason      text not null check (char_length(reason) between 3 and 300),
  created_at  timestamptz not null default now(),
  unique (comment_id, reporter_id)
);

-- ---------------------------------------------------------------------------
-- Blokir pengguna
-- ---------------------------------------------------------------------------
create table if not exists public.user_blocks (
  user_id         uuid not null references auth.users (id) on delete cascade,
  blocked_user_id uuid not null references auth.users (id) on delete cascade,
  created_at      timestamptz not null default now(),
  primary key (user_id, blocked_user_id),
  check (user_id <> blocked_user_id)
);

-- ---------------------------------------------------------------------------
-- RLS
-- ---------------------------------------------------------------------------
alter table public.profiles        enable row level security;
alter table public.library_entries enable row level security;
alter table public.reading_progress enable row level security;
alter table public.read_chapters   enable row level security;
alter table public.comments        enable row level security;
alter table public.comment_reports enable row level security;
alter table public.user_blocks     enable row level security;

-- profiles
drop policy if exists profiles_read on public.profiles;
create policy profiles_read on public.profiles
  for select to authenticated using (true);

drop policy if exists profiles_update_own on public.profiles;
create policy profiles_update_own on public.profiles
  for update to authenticated
  using (id = auth.uid()) with check (id = auth.uid());

-- library_entries
drop policy if exists library_own on public.library_entries;
create policy library_own on public.library_entries
  for all to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

-- reading_progress
drop policy if exists progress_own on public.reading_progress;
create policy progress_own on public.reading_progress
  for all to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

-- read_chapters
drop policy if exists read_chapters_own on public.read_chapters;
create policy read_chapters_own on public.read_chapters
  for all to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

-- comments: semua bisa membaca yang tidak disembunyikan
drop policy if exists comments_read on public.comments;
create policy comments_read on public.comments
  for select to authenticated, anon
  using (is_hidden = false or user_id = auth.uid());

drop policy if exists comments_insert_own on public.comments;
create policy comments_insert_own on public.comments
  for insert to authenticated
  with check (user_id = auth.uid());

drop policy if exists comments_update_own on public.comments;
create policy comments_update_own on public.comments
  for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists comments_delete_own on public.comments;
create policy comments_delete_own on public.comments
  for delete to authenticated using (user_id = auth.uid());

-- comment_reports: user hanya bisa melapor dan melihat laporannya sendiri
drop policy if exists reports_insert_own on public.comment_reports;
create policy reports_insert_own on public.comment_reports
  for insert to authenticated with check (reporter_id = auth.uid());

drop policy if exists reports_read_own on public.comment_reports;
create policy reports_read_own on public.comment_reports
  for select to authenticated using (reporter_id = auth.uid());

-- user_blocks
drop policy if exists blocks_own on public.user_blocks;
create policy blocks_own on public.user_blocks
  for all to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

-- ---------------------------------------------------------------------------
-- Catatan
-- ---------------------------------------------------------------------------
-- Menyembunyikan komentar (moderasi) dilakukan dari dashboard atau dengan
-- service_role di Edge Function. Jangan pernah memakai service_role di app.
