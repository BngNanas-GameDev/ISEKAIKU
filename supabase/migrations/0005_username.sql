-- Isekaiku — Nickname dapat diubah (M7 lanjutan)
-- Jalankan di Supabase Dashboard → SQL Editor, setelah 0004_birth_date.sql.
--
-- Aturan nickname (profiles.username):
-- - 3–24 karakter
-- - huruf, angka, spasi, titik, garis bawah, tanda hubung
-- - unik tanpa membedakan huruf besar/kecil
--
-- Trigger pendaftaran ikut diperbarui agar nama otomatis dari email selalu
-- memenuhi aturan di atas.

-- ---------------------------------------------------------------------------
-- Nama otomatis yang aman
-- ---------------------------------------------------------------------------
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  base text;
begin
  base := regexp_replace(
    lower(split_part(coalesce(new.email, 'user'), '@', 1)),
    '[^a-z0-9_.]',
    '',
    'g'
  );

  if base = '' then
    base := 'user';
  end if;

  insert into public.profiles (id, username)
  values (
    new.id,
    substr(base, 1, 18) || '_' || substr(new.id::text, 1, 4)
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
-- Validasi & keunikan nickname
-- ---------------------------------------------------------------------------
alter table public.profiles
  drop constraint if exists profiles_username_format;

alter table public.profiles
  add constraint profiles_username_format
  check (username ~ '^[A-Za-z0-9][A-Za-z0-9 ._-]{2,23}$');

create unique index if not exists profiles_username_lower_uidx
  on public.profiles (lower(username));
