# Checklist Rilis (M5)

Dokumen ini dipakai sebelum mengunggah ke Google Play.

## 1. Backend

- [ ] Migrasi Supabase sudah dijalankan berurutan:
      `0001_schema.sql`, `0002_forum.sql`, `0003_profile_social.sql`,
      `0004_birth_date.sql`, `0005_username.sql`, `0006_report_user.sql`.
- [ ] Login Google berfungsi di build rilis (bukan hanya debug).
- [ ] Deep link `com.isekaiku.isekaiku://auth-callback` terdaftar di
      Supabase Redirect URLs.

## 2. Keystore rilis (wajib)

```powershell
.\scripts\make-keystore.ps1
```

Simpan **password** dan `android/release-keystore.jks` di tempat aman.
Tanpa keduanya aplikasi tidak bisa di-update di Play Store.

Setelah keystore dibuat:

- [ ] Catat **SHA-1** yang dicetak skrip.
- [ ] Tambahkan SHA-1 itu ke OAuth client **Android** di Google Cloud Console
      (debug dan release berbeda).
- [ ] `android/key.properties` ada (jangan di-commit).
- [ ] `git status` tidak menampilkan `*.jks` / `key.properties`.

## 3. Build

```powershell
.\scripts\build-apk.ps1 -Release            # APK uji (bisa 18+)
.\scripts\build-apk.ps1 -Bundle -PlaySafe   # AAB untuk Play (tanpa 18+)
```

APK rilis berisi semua arsitektur sehingga besar (±100 MB). Unggah **AAB**,
bukan APK; Play akan memecahnya per perangkat.

Pastikan `flutter analyze` bersih dan `flutter test` lulus.

## 4. Google Play Console

- [ ] Target audiens: **18 tahun ke atas** (karena katalog memuat Erotika),
      lalu aktifkan **Restrict Minor Access**.
- [ ] Isi kuesioner rating IARC dengan jujur.
- [ ] Kebijakan privasi **berupa URL publik** (lihat `docs/privacy.md`).
- [ ] Data safety: email, nama, foto profil, Pustaka, konten forum,
      tanggal lahir — sesuai Kebijakan Privasi di aplikasi.
- [ ] Deklarasi UGC: forum punya laporan, blokir, dan moderasi.
- [ ] Tidak ada iklan.
- [ ] Ikon Play Store memakai `assets/icon/play-store-512.png` (512×512).
- [ ] Screenshot tidak menampilkan konten 18+.

## 5. QA di perangkat

- [ ] Onboarding syarat & kebijakan tampil sekali.
- [ ] Login Google → tanggal lahir muncul sekali dan tidak bisa diubah.
- [ ] Ganti akun: riwayat akun lain tidak terbawa.
- [ ] Konten 18+ mati saat belum login / usia < 18.
- [ ] Forum: tulis topik, balas, lapor, hapus milik sendiri.
- [ ] Forward manga di topik Rekomendasi bisa dibuka.
- [ ] Ubah nickname: bentrok nama ditolak.
- [ ] Hemat data: sampul memakai ukuran 256, reader memakai data-saver.
- [ ] Mode webtoon & paged di ujung chapter (lanjut chapter berikutnya).
- [ ] Offline: Pustaka/riwayat tetap terbuka.

## 6. Versi

- [ ] Naikkan `version` di `pubspec.yaml` (mis. `1.0.0+2`).
- [ ] Perbarui `AppConfig.appVersion` bila perlu.
