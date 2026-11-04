-- Isekaiku — Forum komunitas (M7)
-- Jalankan di Supabase Dashboard → SQL Editor, setelah 0001_schema.sql.
--
-- Isi:
--   forum_threads  : topik diskusi
--   forum_posts    : balasan
--   forum_reports  : laporan topik/balasan
--   moderasi teks  : trigger yang sama aturannya dengan lib/core/moderation
--
-- Catatan:
-- - Forum bisa dibaca tanpa login; menulis wajib login (auth.uid()).
-- - Penghapusan topik/balasan oleh pemiliknya sendiri.
-- - Menyembunyikan konten (moderasi) dilakukan dari dashboard dengan
--   service_role. Jangan pernah memakai service_role di aplikasi.

-- ---------------------------------------------------------------------------
-- Fungsi moderasi teks bersama
-- ---------------------------------------------------------------------------
create or replace function public.check_user_text(value text)
returns void
language plpgsql
immutable
as $$
declare body_lower text;
begin
  body_lower := lower(value);

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
end;
$$;

-- ---------------------------------------------------------------------------
-- Topik
-- ---------------------------------------------------------------------------
create table if not exists public.forum_threads (
  id               uuid primary key default gen_random_uuid(),
  user_id          uuid not null references auth.users (id) on delete cascade,
  category         text not null default 'umum'
                   check (category in ('umum', 'rekomendasi', 'bantuan', 'offtopic')),
  title            text not null check (char_length(title) between 5 and 120),
  body             text not null check (char_length(body) between 1 and 5000),
  manga_id         text,
  is_pinned        boolean not null default false,
  is_locked        boolean not null default false,
  is_hidden        boolean not null default false,
  hidden_reason    text,
  reply_count      integer not null default 0,
  last_activity_at timestamptz not null default now(),
  created_at       timestamptz not null default now()
);

create index if not exists forum_threads_activity_idx
  on public.forum_threads (last_activity_at desc);
create index if not exists forum_threads_category_idx
  on public.forum_threads (category, last_activity_at desc);

-- ---------------------------------------------------------------------------
-- Balasan
-- ---------------------------------------------------------------------------
create table if not exists public.forum_posts (
  id            uuid primary key default gen_random_uuid(),
  thread_id     uuid not null references public.forum_threads (id) on delete cascade,
  user_id       uuid not null references auth.users (id) on delete cascade,
  body          text not null check (char_length(body) between 1 and 5000),
  is_hidden     boolean not null default false,
  hidden_reason text,
  created_at    timestamptz not null default now()
);

create index if not exists forum_posts_thread_idx
  on public.forum_posts (thread_id, created_at asc);

-- ---------------------------------------------------------------------------
-- Laporan
-- ---------------------------------------------------------------------------
create table if not exists public.forum_reports (
  id          uuid primary key default gen_random_uuid(),
  target_type text not null check (target_type in ('thread', 'post')),
  target_id   uuid not null,
  reporter_id uuid not null references auth.users (id) on delete cascade,
  reason      text not null check (char_length(reason) between 3 and 300),
  created_at  timestamptz not null default now(),
  unique (target_type, target_id, reporter_id)
);

create index if not exists forum_reports_target_idx
  on public.forum_reports (target_type, target_id);

-- ---------------------------------------------------------------------------
-- Trigger moderasi
-- ---------------------------------------------------------------------------
create or replace function public.forum_threads_moderate()
returns trigger
language plpgsql
as $$
begin
  perform public.check_user_text(new.title || ' ' || new.body);
  return new;
end;
$$;

drop trigger if exists forum_threads_moderate_trigger on public.forum_threads;
create trigger forum_threads_moderate_trigger
  before insert or update of title, body on public.forum_threads
  for each row execute function public.forum_threads_moderate();

create or replace function public.forum_posts_moderate()
returns trigger
language plpgsql
as $$
begin
  perform public.check_user_text(new.body);
  return new;
end;
$$;

drop trigger if exists forum_posts_moderate_trigger on public.forum_posts;
create trigger forum_posts_moderate_trigger
  before insert or update of body on public.forum_posts
  for each row execute function public.forum_posts_moderate();

-- ---------------------------------------------------------------------------
-- Penghitung balasan + aktivitas terakhir
-- ---------------------------------------------------------------------------
create or replace function public.forum_post_sync_thread()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare target uuid;
begin
  target := coalesce(new.thread_id, old.thread_id);

  update public.forum_threads t
     set reply_count = (
           select count(*)
             from public.forum_posts p
            where p.thread_id = target
              and p.is_hidden = false
         ),
         last_activity_at = now()
   where t.id = target;

  return null;
end;
$$;

drop trigger if exists forum_post_sync_thread_trigger on public.forum_posts;
create trigger forum_post_sync_thread_trigger
  after insert or delete or update of is_hidden on public.forum_posts
  for each row execute function public.forum_post_sync_thread();

-- ---------------------------------------------------------------------------
-- RLS
-- ---------------------------------------------------------------------------
alter table public.forum_threads enable row level security;
alter table public.forum_posts   enable row level security;
alter table public.forum_reports enable row level security;

-- Topik: semua boleh membaca yang tidak disembunyikan.
drop policy if exists forum_threads_read on public.forum_threads;
create policy forum_threads_read on public.forum_threads
  for select to anon, authenticated
  using (is_hidden = false or user_id = auth.uid());

drop policy if exists forum_threads_insert_own on public.forum_threads;
create policy forum_threads_insert_own on public.forum_threads
  for insert to authenticated
  with check (
    user_id = auth.uid()
    -- kolom khusus moderator tidak boleh diisi sendiri
    and is_pinned = false
    and is_locked = false
    and is_hidden = false
    and hidden_reason is null
    and reply_count = 0
  );

drop policy if exists forum_threads_delete_own on public.forum_threads;
create policy forum_threads_delete_own on public.forum_threads
  for delete to authenticated
  using (user_id = auth.uid());

-- Balasan: hanya pada topik yang terbuka dan tidak disembunyikan.
drop policy if exists forum_posts_read on public.forum_posts;
create policy forum_posts_read on public.forum_posts
  for select to anon, authenticated
  using (is_hidden = false or user_id = auth.uid());

drop policy if exists forum_posts_insert_own on public.forum_posts;
create policy forum_posts_insert_own on public.forum_posts
  for insert to authenticated
  with check (
    user_id = auth.uid()
    and is_hidden = false
    and hidden_reason is null
    and exists (
      select 1
        from public.forum_threads t
       where t.id = thread_id
         and t.is_locked = false
    )
  );

drop policy if exists forum_posts_delete_own on public.forum_posts;
create policy forum_posts_delete_own on public.forum_posts
  for delete to authenticated
  using (user_id = auth.uid());

-- Laporan: kirim dan lihat milik sendiri.
drop policy if exists forum_reports_insert_own on public.forum_reports;
create policy forum_reports_insert_own on public.forum_reports
  for insert to authenticated with check (reporter_id = auth.uid());

drop policy if exists forum_reports_read_own on public.forum_reports;
create policy forum_reports_read_own on public.forum_reports
  for select to authenticated using (reporter_id = auth.uid());

-- ---------------------------------------------------------------------------
-- Profil: nama penulis forum perlu terbaca tanpa login (hanya username).
-- ---------------------------------------------------------------------------
drop policy if exists profiles_read_public on public.profiles;
create policy profiles_read_public on public.profiles
  for select to anon using (true);
