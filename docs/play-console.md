# Panduan Play Console (internal → closed → produksi)

Panduan ini melengkapi `docs/rilis.md`. Isian di bawah adalah saran;
jawaban akhir tetap tanggung jawab pemilik aplikasi.

## 0. Dua jenis build

| Build | Perintah | Konten 18+ |
|---|---|---|
| Play Store | `.\scripts\build-apk.ps1 -Bundle -PlaySafe` | Dinonaktifkan |
| APK langsung | `.\scripts\build-apk.ps1 -Release` | Bisa diaktifkan |

**Gunakan build `-PlaySafe` untuk Play Store.** Google Play melarang konten
seksual eksplisit; gate usia tidak membuatnya otomatis diizinkan.

## 1. Prasyarat akun

- Akun Google Play Developer aktif (biaya sekali US$25) + verifikasi identitas.
- **Akun personal baru** (dibuat setelah 13 Nov 2023) wajib:
  - uji tertutup dengan **minimal 12 penguji** yang tetap *opted-in*, dan
  - berjalan **14 hari berturut-turut** sebelum bisa mengajukan akses produksi.
- Akun organisasi tidak terkena aturan 12 penguji.

## 2. Buat aplikasi

- **Nama**: `Isekaiku`
- **Bahasa default**: Indonesia
- **Jenis**: Aplikasi (bukan game)
- **Gratis**: Ya
- **Kategori**: Comics (atau Books & Reference)

## 3. App content (isi wajib)

### Privacy policy
URL setelah GitHub Pages aktif (Settings → Pages → `main` / `/docs`):
```
https://bngnanas-gamedev.github.io/ISEKAIKU/privacy.html
```

### App access
- Membaca manga bisa tanpa login.
- Forum dan sinkronisasi memerlukan login Google.
- Pilih **“All or some functionality is restricted”**, lalu beri instruksi:
  ```
  Baca manga: langsung tanpa akun.
  Forum/Pustaka sinkron: masuk dengan akun penguji di bawah.
  ```
- Siapkan **akun Google penguji** (jangan akun pribadi) dan tuliskan
  email + password di kolom instruksi. Hapus aksesnya setelah review.

### Ads
- **Tidak ada iklan.**

### Content rating (IARC)
Jawab jujur. Untuk build PlaySafe:
- Kekerasan: ya (adegan manga)
- Konten seksual: ya, *suggestive/mild* (Erotika tidak tersedia)
- Bahasa kasar: ya
- Alkohol/rokok/narkoba: ya (referensi cerita)
- Judi: ya (referensi cerita) — bukan judi online
- UGC: **ya** (forum)
- Pengguna berinteraksi: **ya** (forum)
- Berbagi lokasi: tidak
- Pembelian digital: tidak
- Iklan: tidak

### Target audience
- Pilih **18 tahun ke atas** saja.
- Aktifkan **Restrict Minor Access** (batasi akses minor).
- Jangan mencentang kelompok usia anak.

### Data safety
| Data | Dikumpulkan | Dibagikan | Tujuan |
|---|---|---|---|
| Email | Ya | Tidak | Akun |
| Nama/foto profil | Ya | Tidak | Profil publik |
| Riwayat baca/Pustaka | Ya | Tidak | Sinkronisasi |
| Konten forum | Ya | Ya (publik) | Forum |
| Tanggal lahir | Ya | Tidak | Batas usia |
| ID pengguna | Ya | Tidak | Akun/sinkronisasi |

- Terenkripsi saat transit: **ya**.
- Pengguna bisa minta hapus data: **ya** (via GitHub Issues).
- Tidak ada iklan/tracking pihak ketiga.

### Deklarasi lain
- Government apps: **tidak**
- Financial features: **tidak**
- Health: **tidak**
- News: **tidak**

### UGC (forum)
- Moderasi: trigger server + laporan konten + laporan pengguna.
- Blokir pengguna: konten penulis yang diblokir disembunyikan.
- Pemilik dapat menghapus topik/balasan sendiri.
- Wajib mendeklarasikan forum sebagai UGC.

## 4. Store listing

- **Nama**: `Isekaiku` (maks. 30)
- **Deskripsi singkat** (maks. 80):
  ```
  Pembaca manga tanpa iklan. Katalog MangaDex, Pustaka, dan forum komunitas.
  ```
- **Deskripsi lengkap** (contoh, sesuaikan):
  ```
  Isekaiku adalah pembaca manga lokal-first tanpa iklan.

  • Jelajah katalog MangaDex: populer, terbaru, genre, dan pencarian.
  • Baca per halaman atau mode webtoon, dengan pengaturan hemat data.
  • Simpan manga ke Pustaka dan lanjutkan bacaan dari halaman terakhir.
  • Sinkronkan Pustaka antar perangkat dengan akun Google (opsional).
  • Forum komunitas: rekomendasi manga, tanya jawab, dan berbagi bacaan.

  Semua fitur baca tetap berjalan tanpa akun. Konten manga milik pemegang
  hak cipta dan disediakan oleh MangaDex.
  ```
- **Kontak**: email aktif + `https://github.com/BngNanas-GameDev/ISEKAIKU`
- **Grafis**:
  - Ikon 512×512: `assets/icon/play-store-512.png`
  - Feature graphic 1024×500: `assets/store/feature-graphic-1024x500.png`
  - Screenshot ponsel 2–8: Beranda, Detail, Reader, Pustaka, Forum, Akun
  - Screenshot **tanpa** konten 18+ (pakai build PlaySafe)
- Ambil screenshot dari HP:
  ```powershell
  adb exec-out screencap -p > screenshot-beranda.png
  ```

## 5. Penguji internal

1. Play Console → **Testing → Internal testing** → **Create new release**.
2. Upload `app-release.aab` hasil `-Bundle -PlaySafe`.
3. Isi release notes, lalu **Save → Review → Start rollout**.
4. Tab **Testers** → **Create email list**, masukkan email penguji
   (maks. 100 untuk internal).
5. Salin **opt-in URL** dan kirim ke penguji.
6. Penguji membuka URL → install dari Play → aplikasi muncul sebagai
   “Isekaiku (internal)”.
7. Uji: login, Pustaka, forum, ganti akun, hemat data, reader.

Checklist penguji:
- [ ] Login Google berhasil.
- [ ] Tanggal lahir muncul sekali.
- [ ] Baca chapter, progres tersimpan.
- [ ] Pustaka & riwayat tidak tercampur antar akun.
- [ ] Forum: tulis, balas, lapor, hapus.
- [ ] Forward manga di Rekomendasi.
- [ ] Hemat data & mode webtoon.
- [ ] Tidak ada crash saat pindah tab.

### Template pesan untuk penguji

```
Halo! Aku butuh bantuan uji coba aplikasi Isekaiku (Android).

1. Buka link opt-in ini: <TEMPEL OPT-IN URL>
2. Masuk dengan akun Google yang kamu daftarkan.
3. Install "Isekaiku" dari Play Store.
4. Coba: baca 1 chapter, simpan ke Pustaka, tulis 1 topik forum.
5. Laporkan bug/kesan lewat <LINK GRUP/EMAIL>.

Penting: jangan uninstall selama 14 hari (syarat uji tertutup Play).
Terima kasih!
```

## 6. Pengujian tertutup (closed testing)

1. **Testing → Closed testing** → buat track (mis. `alpha`).
2. Upload AAB yang sama (versi lebih tinggi bila sudah pernah upload).
3. Tambahkan **minimal 12 penguji** ke email list; pastikan mereka
   **opt-in dan tetap terpasang selama 14 hari**.
4. Kumpulkan umpan balik, perbaiki, lalu rilis update.
5. Setelah 14 hari, ajukan **Apply for production access** di
   **Dashboard → Production access**.

## 7. Produksi

1. **Production → Create new release** → upload/promote AAB PlaySafe.
2. Pilih negara (Indonesia dulu), rollout **20% → 50% → 100%**.
3. Pastikan semua bagian **App content** hijau (privacy, data safety,
   rating, target audience, app access, ads).
4. Ajukan review. Waktu review biasanya beberapa jam–7 hari.
5. Pantau **Android vitals** (crash/ANR) dan ulasan.

## 8. Risiko penolakan yang paling umum

- Konten Erotika di katalog → **gunakan `-PlaySafe`**.
- URL kebijakan privasi 404 → aktifkan GitHub Pages dan tes URL.
- Data safety tidak cocok dengan perilaku aplikasi.
- Target audiens memasukkan anak-anak padahal ada forum/18+.
- Tidak ada akun penguji untuk fitur yang butuh login.
- UGC tanpa laporan/blokir → forum sudah punya laporan konten,
  laporan pengguna, dan blokir; pastikan deklarasi UGC diisi.
- Screenshot menampilkan konten dewasa.

## 9. Setelah rilis

- Aktifkan cron keep-alive Supabase (lihat `docs/supabase-setup.md`).
- Simpan keystore + password; tanpa itu update tidak mungkin.
- Naikkan `version` (`1.0.0+2`, dst.) setiap upload.
