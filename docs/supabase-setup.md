# Setup Supabase (free tier)

Panduan ini menyiapkan backend untuk **sinkronisasi Pustaka** dan **forum
komunitas**. Aplikasi tetap *local-first*: semua fitur baca jalan tanpa login
dan tanpa internet. Supabase hanya lapisan tambahan.

> Jangan pernah menaruh `service_role` key di aplikasi. Yang dipakai klien
> hanya `anon` key.

---

## 1. Buat proyek

1. Buka <https://supabase.com/dashboard> → **New project**
2. Pilih region **Southeast Asia (Singapore)** — paling dekat ke Indonesia
3. Simpan **database password** di tempat aman
4. Tunggu provisioning selesai (±2 menit)

## 2. Jalankan skema

1. Buka **SQL Editor** di dashboard
2. Salin seluruh isi `supabase/migrations/0001_schema.sql` → **Run**
3. Salin seluruh isi `supabase/migrations/0002_forum.sql` → **Run**
4. Salin seluruh isi `supabase/migrations/0003_profile_social.sql` → **Run**
5. Salin seluruh isi `supabase/migrations/0004_birth_date.sql` → **Run**
6. Salin seluruh isi `supabase/migrations/0005_username.sql` → **Run**
7. Salin seluruh isi `supabase/migrations/0006_report_user.sql` → **Run**

Skrip pertama membuat:

| Tabel | Isi |
|---|---|
| `profiles` | username publik |
| `library_entries` | manga diikuti |
| `reading_progress` | posisi baca terakhir per manga |
| `read_chapters` | chapter yang sudah dibuka |
| `comments` | komentar per manga |
| `comment_reports` | laporan komentar |
| `user_blocks` | daftar blokir |

Skrip kedua (`0002_forum.sql`) membuat forum:

| Tabel | Isi |
|---|---|
| `forum_threads` | topik diskusi (judul, isi, kategori) |
| `forum_posts` | balasan tiap topik |
| `forum_reports` | laporan topik/balasan |

Forum bisa **dibaca tanpa login**; menulis, melapor, dan menghapus milik
sendiri wajib login Google. Kategori: `umum`, `rekomendasi`, `bantuan`,
`offtopic`.

Skrip ketiga (`0003_profile_social.sql`) menambah fitur profil:

| Perubahan | Isi |
|---|---|
| `profiles.bio` | bio publik (maks. 160 karakter) |
| `profiles.avatar_url` | foto profil (opsional) |
| `forum_threads.manga_*` | manga yang dilampirkan pada topik Rekomendasi |
| `user_follows` | pengikut / mengikuti antar pengguna |

Skrip keempat (`0004_birth_date.sql`) menambah `profiles.birth_date` dengan
trigger yang membuat tanggal lahir:

- wajib diisi sekali setelah login (lewat aplikasi),
- **tidak bisa diubah/dikosongkan** setelah tersimpan,
- minimal usia 13 tahun dan maksimal 120 tahun.

Status 18+ dihitung dari tanggal lahir, jadi tidak pernah kedaluwarsa.

Skrip kelima (`0005_username.sql`) membuat nickname bisa diubah: validasi
3–24 karakter dan keunikan tanpa membedakan huruf besar/kecil.
Skrip keenam (`0006_report_user.sql`) mengizinkan `forum_reports` menerima
`target_type = 'user'` untuk laporan pengguna (syarat UGC Play).

Halaman **Akun** menampilkan foto profil (dari Google), bio, jumlah manga
dibaca, pengikut, mengikuti, dan daftar thread yang pernah ditulis.

Skema juga memasang **trigger moderasi** di `comments`, `forum_threads`, dan
`forum_posts` yang menolak:

- tautan eksternal (termasuk `[.]`)
- kata kunci judi online
- kata kunci narkoba

Ini lapisan server; filter di aplikasi (`lib/core/moderation`) hanya untuk
umpan balik cepat.

### Menyembunyikan konten (moderasi manual)

Jalankan dari SQL Editor (bukan dari aplikasi — butuh `service_role`):

```sql
-- sembunyikan topik
update public.forum_threads
   set is_hidden = true, hidden_reason = 'spam'
 where id = '<uuid>';

-- sembunyikan balasan (reply_count otomatis menyesuaikan)
update public.forum_posts
   set is_hidden = true, hidden_reason = 'spam'
 where id = '<uuid>';

-- sematkan / kunci topik
update public.forum_threads set is_pinned = true where id = '<uuid>';
update public.forum_threads set is_locked = true where id = '<uuid>';
```

Lihat laporan yang masuk:

```sql
select r.created_at, r.target_type, r.target_id, r.reason, p.username
  from public.forum_reports r
  join public.profiles p on p.id = r.reporter_id
 order by r.created_at desc;
```

## 3. Ambil kredensial

Dashboard → **Settings → API**:

| Nilai | Dipakai di |
|---|---|
| `Project URL` | `SUPABASE_URL` |
| `anon public` | `SUPABASE_ANON_KEY` (aman di klien, dilindungi RLS) |
| `service_role` | **JANGAN** dipakai di app |

Untuk pengembangan, simpan sebagai `--dart-define`:

```powershell
flutter run --dart-define=SUPABASE_URL=https://xxxx.supabase.co `
            --dart-define=SUPABASE_ANON_KEY=eyJhbGciOi...
```

## 4. Auth

### Opsi A — Login Google (disarankan untuk free tier)

Tidak butuh pengiriman email, jadi tidak terkena limit SMTP.

1. **Authentication → Providers → Google** → aktifkan
2. Buat OAuth client di Google Cloud Console (tipe *Android* dan *Web*)
3. Daftarkan **SHA-1** untuk **debug dan release** — keduanya berbeda:

```powershell
# debug
keytool -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" `
  -alias androiddebugkey -storepass android -keypass android
```

4. Isi *Authorized redirect URI* dengan callback Supabase:
   `https://<ref>.supabase.co/auth/v1/callback`
5. Tambahkan scheme redirect di `android/app/src/main/AndroidManifest.xml`

SHA-1 yang salah adalah penyebab paling umum "login tidak terjadi apa-apa".

### Opsi B — Email + password

1. **Authentication → Providers → Email** → aktif
2. Matikan **Confirm email** (karena SMTP bawaan sangat terbatas)
3. Aktifkan **Captcha** (Turnstile/hCaptcha) agar tidak dibanjiri akun palsu

Konsekuensi: email palsu bisa lolos dan reset password tidak tersedia.

## 5. Keep-alive agar proyek tidak di-pause

Free tier mem-pause proyek setelah ±7 hari tanpa request. Satu request per hari
sudah cukup.

### cron-job.org (gratis, disarankan)

1. Daftar di <https://cron-job.org>
2. **Create cronjob**
3. URL:
   ```
   https://<ref>.supabase.co/rest/v1/
   ```
4. **Advanced → Headers**:
   ```
   apikey: <anon key>
   ```
5. Jadwal: **every day**, pilih jam yang jarang dipakai (mis. 03:00 WIB)
6. Simpan, lalu klik **Test run** — status `200`/`401` dua-duanya berarti
   aktivitas tercatat

Alternatif: GitHub Actions `schedule` (cron), tapi workflow otomatis mati
setelah repo 60 hari tanpa commit.

Catatan: keep-alive mencegah *pause*, bukan menggantikan backup. Backup tetap
lewat **Pustaka → Backup Pustaka → Ekspor**.

## 6. Integrasi Flutter (nanti)

Saat mulai menulis kode akun:

1. Tambah dependensi `supabase_flutter`
2. Inisialisasi di `main()` **hanya jika** URL & key tersedia
3. Simpan sesi di `flutter_secure_storage` (bukan `shared_preferences`)
4. Login bersifat **opsional**; tanpa login aplikasi tetap penuh fungsi
5. Sinkronisasi: `updated_at` terbaru menang (last-write-wins)

## 7. Batas free tier & kapan naik Pro

| Item | Free | Catatan |
|---|---|---|
| Database | 500 MB | Teks saja; sangat lega |
| Egress | 5 GB/bulan | Sync teks kecil |
| Auth MAU | 50.000 | Cukup |
| Backup harian | ❌ | Pakai ekspor JSON |
| Pause | ±7 hari idle | Diatasi keep-alive |

Naik ke Pro ($25/bln) saat butuh: backup harian, reset password via email,
atau trafik sudah ramai.

## 8. Checklist keamanan

- [ ] `service_role` tidak ada di kode/aplikasi
- [ ] RLS aktif di semua tabel (sudah di skrip)
- [ ] Uji dengan **dua akun** berbeda: pastikan tidak bisa saling melihat data
- [ ] Sesi disimpan di secure storage
- [ ] Captcha aktif kalau signup email dibuka
- [ ] Hapus akun berfungsi (Edge Function + `service_role` di server)
- [ ] Privacy Policy & Data Safety di Play Store diperbarui
