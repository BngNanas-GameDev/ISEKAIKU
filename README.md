# Isekaiku

Portal Android untuk membaca manga (MangaDex API resmi) dan memutar anime dari
sumber file milik sendiri (Gofile / URL langsung).

Status: **M0 selesai** — skeleton, design system, wordmark, build web & test.

## Stack

| Aspek | Pilihan |
|---|---|
| Platform | Android (web hanya untuk preview development) |
| State / DI | Riverpod 2 |
| Model | freezed + json_serializable |
| Navigasi | go_router |
| HTTP | Dio + throttle 1 req/detik + retry 429 |
| Player | media_kit (libmpv) |
| Font | Asimov (Apache 2.0) |
| Tema | Dark-only, palet `#222831 #31363F #76ABAE #EEEEEE` |

## Menjalankan

```powershell
flutter pub get
flutter analyze
flutter test
```

Preview cepat di browser (tanpa HP):

```powershell
flutter run -d edge
# atau build statis
flutter build web --release
python -m http.server 8090 --directory build\web
```

Buka `http://127.0.0.1:8090` untuk app, atau
`http://127.0.0.1:8090/?dev=design` untuk halaman Design System.

### Jalankan di HP (wireless debugging)

`scripts\_env.ps1` mencari Flutter, JDK, Android SDK, dan adb secara otomatis
(environment variable dulu, lalu lokasi umum). Tidak perlu hardcode path mesin.
Kalau perlu di-override, set `FLUTTER_ROOT`, `JAVA_HOME`, `ANDROID_HOME`, atau
`ADB` sebelum menjalankan script.

```powershell
.\scripts\connect-phone.ps1 -Discover       # cari port HP lewat mDNS + flutter run
.\scripts\deploy-phone.ps1                  # build + install + launch + screenshot
```

Pairing pertama kali (sekali per HP):

```powershell
.\scripts\connect-phone.ps1 -Pair -PairPort 46247
# masukkan kode 6 digit dari menu "Pair device with pairing code"
```

Setelah pairing, port **connect** berbeda dari port pairing. `-Discover` mencari
port itu lewat `adb mdns services`; atau isi manual: `-Ip 192.168.1.3 -Port 37331`.

Catatan HyperOS/MIUI: instalasi lewat adb butuh **Developer options → Install via
USB** aktif. Kalau tetap `INSTALL_FAILED_USER_RESTRICTED`, APK bisa dipasang
manual dari File Manager (`Download/isekaiku-debug.apk`).

### Setup Android SDK + JDK

Kalau `flutter doctor` bilang "Unable to locate Android SDK":

```powershell
# 1. JDK 17 (wajib untuk AGP 8.7.3)
#    Unduh Temurin 17 x64 zip, ekstrak ke D:\Android\jdk17

# 2. cmdline-tools
#    Unduh commandlinetools-win-*_latest.zip, ekstrak ke
#    <ANDROID_HOME>\cmdline-tools\latest (harus ada folder bin/ di dalamnya)

# 3. Set environment (user-level, sekali saja)
[Environment]::SetEnvironmentVariable("ANDROID_HOME", "D:\Android\sdk", "User")
[Environment]::SetEnvironmentVariable("JAVA_HOME", "D:\Android\jdk17", "User")

# 4. Pasang paket SDK yang dibutuhkan proyek
.\scripts\setup-android-sdk.ps1
```

### Workaround DNS (opsional, mesin tertentu)

Beberapa mesin punya DNS lokal yang gagal me-resolve host build
(`UnknownHostException` acak). Kalau itu terjadi, arahkan Gradle memakai hosts
file statis lewat `android/gradle.properties`:

- `org.gradle.jvmargs=... -Djdk.net.hosts.file=C:/Android/hosts-java.txt`
- `systemProp.jdk.net.hosts.file=C:/Android/hosts-java.txt`

Di mesin ini DNS normal, jadi kedua baris itu sengaja dinonaktifkan. Kalau
Gradle error jaringan, coba dulu hentikan daemon:

```powershell
cd android
.\gradlew.bat --stop
```


## Struktur

```
lib/
  main.dart
  core/
    licensing.dart        # registrasi lisensi font (Apache 2.0)
    network/
      api_client.dart     # Dio + throttle 1 req/detik + retry 429
      api_exception.dart
      doh/
        doh_resolver.dart       # query DoH + cache + fallback provider
        doh_http_overrides.dart # pasang DoH ke semua HttpClient aplikasi
    theme/                # colors, typography, spacing, theme, fonts
    widgets/              # IsekaikuWordmark + Design System preview
    storage/              # StorageService (SharedPreferences) + notifier persisten
  features/
    manga/                # M1: browse, search, detail, reader
    library/              # M2: Pustaka (diikuti + riwayat), model & store lokal
  sources/                # (M3+) VideoSourceProvider
assets/
  fonts/                  # 5 file Asimov + LICENSE + NOTICE
scripts/
  _env.ps1                # auto-detect Flutter/JDK/SDK/adb (dipakai script lain)
  connect-phone.ps1       # pairing / connect wireless debugging + flutter run
  deploy-phone.ps1        # build + install + launch + screenshot
  setup-android-sdk.ps1   # pasang paket SDK yang dibutuhkan (idempoten)
tools/
  doh_probe.dart          # diagnostik: query DoH + HTTPS ke IP hasil DoH
  tls_http_probe.dart     # diagnostik: TLS handshake + HTTP/1.1 mentah
  sni_probe.dart          # diagnostik: deteksi blokir berbasis SNI
  mock_mangadex.py        # server tiruan MangaDex untuk uji UI offline
  api_probe.dart          # diagnostik: filter API MangaDex (chapter, bahasa)
  chapters_probe.dart     # diagnostik: jumlah chapter per judul
supabase/
  migrations/             # skema Postgres + RLS + trigger moderasi
docs/
  supabase-setup.md       # panduan setup akun, RLS, keep-alive free tier
test/
  doh_resolver_test.dart  # unit test parser + provider DoH
  mangadex_mapper_test.dart
  manga_test.dart
  chapter_availability_test.dart
  chapter_range_test.dart
  library_store_test.dart
  library_page_test.dart
  library_backup_test.dart
  reading_progress_test.dart
  content_moderation_test.dart
  widget_test.dart        # smoke test tema & wordmark
```

## Design tokens

- Background `#222831`, card `#31363F`, aksen `#76ABAE`, teks `#EEEEEE`
- Teks sekunder `#B4B9BE`, outline `#5B626C`, divider `#3D434C`
- Error `#F2B8B5`, success `#8FC9A0`, warning `#E3C08A`
- Reader `#1B1F26`, player `#0E1114`
- Tipografi: Asimov Extra Wide (display/wordmark), Asimov Wide (judul/label),
  Asimov (body), Asimov Narrow (metadata). Tidak memakai bold sintetis.

Wordmark: `ISEKAI` = `#EEEEEE`, `KU` = `#76ABAE`, auto-scale di layar sempit.

## Lisensi font

Asimov Font © KineticPlasma Fonts, turunan Roboto (Google), Apache License 2.0.
Teks lisensi lengkap: `assets/fonts/LICENSE-Asimov.txt`, atribusi:
`assets/fonts/NOTICE-Asimov.txt`. Keduanya didaftarkan ke `LicenseRegistry`
sehingga tampil di halaman lisensi aplikasi.

## Roadmap

Manga-first sampai rilis. Anime ditunda sampai aplikasi terbukti dipakai.

- [x] M0 Skeleton, design system, wordmark, preview web
- [x] M1 MangaDex: browse populer/terbaru, search, detail, chapter list, reader
      (paged + webtoon, prefetch, hemat kuota), error state informatif
- [x] M2 Pustaka lokal: follow, riwayat baca, setting reader persisten, DoH
      (StorageService + provider persisten, Pustaka 2 tab, tombol ikuti,
      riwayat otomatis di reader)
- [x] M3 Kedalaman baca: progres halaman, kartu "Lanjut baca", badge rentang
      chapter + Lengkap, sembunyikan judul tanpa chapter, bahasa ketat,
      ekspor/impor Pustaka, filter moderasi
- [ ] M4 Import koleksi lokal (folder/CBZ), jelajah genre/filter, riwayat
      pencarian, urutkan Pustaka
- [ ] M5 Rilis: skeleton/empty state, hemat data, lokalisasi, ikon adaptif,
      splash, release signing, QA
- [ ] M6 (pasca-rilis) Akun Supabase + sinkronisasi Pustaka
- [ ] M7 (pasca-rilis) Komentar/forum per manga
- [ ] M8 (ditunda) Anime: koleksi lokal, provider video, player media_kit

## Akun & sinkronisasi (persiapan)

Skema backend opsional ada di `supabase/migrations/0001_schema.sql`: profil,
Pustaka, progres baca, chapter terbaca, komentar, laporan, dan blokir —
lengkap dengan **RLS** dan **trigger moderasi** server-side.

Panduan langkah demi langkah (login Google, SHA-1 debug/release, dan
keep-alive free tier lewat cron-job.org): `docs/supabase-setup.md`.

Aplikasi tetap **local-first**: tanpa login, semua fitur baca tetap jalan.

Backup manual: **Pustaka → Backup Pustaka → Ekspor ke clipboard** (impor
bersifat menggabungkan, jadi aman diulang).

## Catatan kepatuhan

MangaDex: wajib User-Agent unik, maksimal ±1 request/detik, atribusi
"Data provided by MangaDex", tanpa penggunaan komersial tanpa izin.

Gofile hanya untuk file yang kamu miliki haknya. Aplikasi tidak menyediakan
katalog streaming bajakan dan tidak melakukan scraping situs berhak cipta.

## Kalau MangaDex diblokir ISP

Beberapa ISP (mis. Telkomsel/IndiHome/MyRepublic) membajak DNS dan mengalihkan
`api.mangadex.org` ke halaman blokir (`block.<isp>.co.id`), sehingga aplikasi
menampilkan pesan "Tidak bisa terhubung ke server".

**Aplikasi sudah menangani ini otomatis lewat DNS-over-HTTPS (DoH).** Setiap
`HttpClient` di aplikasi (Dio, cached_network_image) memakai resolver DoH untuk
mencari IP asli `api.mangadex.org`, lalu tetap memakai TLS normal dengan
hostname asli untuk SNI + validasi sertifikat. Jadi tidak perlu VPN.

Kalau ingin mematikan DoH (mis. untuk debugging atau jaringan yang memblokir
DoH juga):

```powershell
flutter run --dart-define=DISABLE_DOH=true
```

Kalau ISP ternyata juga memblokir di level IP/SNI (bukan hanya DNS), DoH tidak
cukup — pakai VPN atau arahkan base URL ke mirror/proxy yang kamu percaya:

```powershell
flutter build apk --debug --dart-define=MANGADEX_BASE_URL=https://mirror.contoh
```

Diagnostik DoH tersedia di `tools/`:

```powershell
dart run tools/doh_probe.dart        # query DoH + coba HTTPS ke IP hasil DoH
dart run tools/tls_http_probe.dart   # TLS handshake + HTTP/1.1 mentah
dart run tools/sni_probe.dart        # uji blokir berbasis SNI
```

## Uji UI tanpa MangaDex

```powershell
python tools/mock_mangadex.py 8099
flutter build web --release --dart-define=MANGADEX_BASE_URL=http://127.0.0.1:8099
python -m http.server 8090 --directory build\web
```
