-- Isekaiku — Tanggal lahir sekali isi (M7 lanjutan)
-- Jalankan di Supabase Dashboard → SQL Editor, setelah 0003_profile_social.sql.
--
-- Aturan:
-- - Tanggal lahir disimpan di profil, diisi sekali setelah login.
-- - Setelah terisi, TIDAK bisa diubah/dikosongkan (dijaga trigger).
-- - Usia minimum aplikasi 13 tahun; validasi juga dicek di server.
-- - Status 18+ dihitung ulang dari tanggal lahir, jadi tidak pernah
--   "kedaluwarsa" dan tidak perlu isi ulang.

alter table public.profiles
  add column if not exists birth_date date;

create or replace function public.profiles_guard_birth_date()
returns trigger
language plpgsql
as $$
begin
  -- Sekali terisi, tidak boleh berubah (termasuk dikosongkan).
  if old.birth_date is not null
     and new.birth_date is distinct from old.birth_date then
    raise exception 'Tanggal lahir tidak dapat diubah.'
      using errcode = 'check_violation';
  end if;

  if new.birth_date is not null then
    if new.birth_date > (current_date - interval '13 years') then
      raise exception 'Usia minimum 13 tahun.'
        using errcode = 'check_violation';
    end if;

    if new.birth_date < (current_date - interval '120 years') then
      raise exception 'Tanggal lahir tidak valid.'
        using errcode = 'check_violation';
    end if;
  end if;

  return new;
end;
$$;

drop trigger if exists profiles_guard_birth_date_trigger on public.profiles;
create trigger profiles_guard_birth_date_trigger
  before update of birth_date on public.profiles
  for each row execute function public.profiles_guard_birth_date();
