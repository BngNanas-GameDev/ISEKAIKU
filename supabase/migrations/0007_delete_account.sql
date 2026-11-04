-- Isekaiku — Hapus akun mandiri (syarat Google Play)
-- Jalankan setelah 0006_report_user.sql.
--
-- Fungsi security definer menghapus auth.users milik pemanggil. Semua tabel
-- dengan foreign key ON DELETE CASCADE (profil, Pustaka, forum, dll.) ikut
-- terhapus. Klien tidak pernah memegang service_role.

create or replace function public.delete_my_account()
returns void
language plpgsql
security definer
set search_path = public, auth
as $$
begin
  if auth.uid() is null then
    raise exception 'Harus masuk terlebih dahulu'
      using errcode = 'insufficient_privilege';
  end if;

  delete from auth.users where id = auth.uid();
end;
$$;

revoke all on function public.delete_my_account() from public;
grant execute on function public.delete_my_account() to authenticated;
