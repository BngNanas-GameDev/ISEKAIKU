-- Isekaiku — Laporan pengguna (kebijakan UGC Play)
-- Jalankan setelah 0005_username.sql.
--
-- forum_reports sebelumnya hanya menerima 'thread' dan 'post'. Sekarang
-- menerima 'user' agar pengguna bisa melaporkan akun, bukan hanya konten.

alter table public.forum_reports
  drop constraint if exists forum_reports_target_type_check;

alter table public.forum_reports
  add constraint forum_reports_target_type_check
  check (target_type in ('thread', 'post', 'user'));
