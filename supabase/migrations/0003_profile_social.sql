-- Isekaiku — Profil sosial + forward manga (M7 lanjutan)
-- Jalankan di Supabase Dashboard → SQL Editor, setelah 0002_forum.sql.
--
-- Isi:
--   profiles.bio / avatar_url          : profil publik
--   forum_threads.manga_*              : manga yang direkomendasikan
--   user_follows                       : pengikut / mengikuti

-- ---------------------------------------------------------------------------
-- Profil
-- ---------------------------------------------------------------------------
alter table public.profiles
  add column if not exists bio text check (char_length(bio) <= 160);

alter table public.profiles
  add column if not exists avatar_url text;

-- ---------------------------------------------------------------------------
-- Forward manga pada topik forum (kategori "rekomendasi")
-- ---------------------------------------------------------------------------
alter table public.forum_threads
  add column if not exists manga_title text;

alter table public.forum_threads
  add column if not exists manga_cover_url text;

-- ---------------------------------------------------------------------------
-- Pengikut / mengikuti
-- ---------------------------------------------------------------------------
create table if not exists public.user_follows (
  follower_id  uuid not null references auth.users (id) on delete cascade,
  following_id uuid not null references auth.users (id) on delete cascade,
  created_at   timestamptz not null default now(),
  primary key (follower_id, following_id),
  check (follower_id <> following_id)
);

create index if not exists user_follows_following_idx
  on public.user_follows (following_id);

alter table public.user_follows enable row level security;

-- Daftar pengikut bersifat publik (hanya id; username diambil dari profiles).
drop policy if exists user_follows_read on public.user_follows;
create policy user_follows_read on public.user_follows
  for select to anon, authenticated using (true);

drop policy if exists user_follows_insert_own on public.user_follows;
create policy user_follows_insert_own on public.user_follows
  for insert to authenticated with check (follower_id = auth.uid());

drop policy if exists user_follows_delete_own on public.user_follows;
create policy user_follows_delete_own on public.user_follows
  for delete to authenticated using (follower_id = auth.uid());
