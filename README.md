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

Setup yang dipakai di mesin ini:

| Komponen | Lokasi |
|---|---|
| JDK 17 | `C:\Program Files\Eclipse Adoptium\jdk-17.0.20.101-hotspot` |
| Android SDK | `C:\Android\sdk` (platform 35/36, build-tools 35, NDK 26.3) |
| adb | `C:\Android\sdk\platform-tools\adb.exe` |

```powershell
.\scripts\connect-phone.ps1 -Ip 192.168.6.21 -Port 35183
.\scripts\deploy-phone.ps1                 # build + install + launch + screenshot
```

Pairing pertama kali (sekali per HP):

```powershell
.\scripts\connect-phone.ps1 -Pair -PairPort 40817
# masukkan kode 6 digit dari menu "Pair device with pairing code"
```

Catatan HyperOS/MIUI: instalasi lewat adb butuh **Developer options → Install via
USB** aktif. Kalau tetap `INSTALL_FAILED_USER_RESTRICTED`, APK bisa dipasang
manual dari File Manager (`Download/isekaiku-debug.apk`).

### Workaround DNS (khusus mesin ini)

DNS jaringan lokal sering gagal me-resolve host build (`UnknownHostException`
acak). Gradle diarahkan memakai hosts file statis:

- `C:\Android\hosts-java.txt` — pemetaan host → IP CDN
- `android/gradle.properties` → `org.gradle.jvmargs=... -Djdk.net.hosts.file=...`

Kalau `flutter doctor`/Gradle error jaringan, hentikan daemon dulu:

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
    network/              # api_client (throttle + retry), api_exception
    theme/                # colors, typography, spacing, theme, fonts
    widgets/              # IsekaikuWordmark + Design System preview
  features/               # (M1+) manga, anime, player, library, settings
  sources/                # (M3+) VideoSourceProvider
assets/
  fonts/                  # 5 file Asimov + LICENSE + NOTICE
scripts/
  connect-phone.ps1       # pairing / connect wireless debugging
  deploy-phone.ps1        # build + install + launch + screenshot
test/
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

- [x] M0 Skeleton, design system, wordmark, preview web
- [ ] M1 MangaDex: browse, search, detail, chapter list, reader
- [ ] M2 Reader settings, prefetch, follow lokal, history, atribusi
- [ ] M3 Gofile provider, koleksi anime manual, fallback WebView
- [ ] M4 Player media_kit: resume, gesture, subtitle, kecepatan
- [ ] M5 Polish, ikon adaptif, splash, release signing

## Catatan kepatuhan

MangaDex: wajib User-Agent unik, maksimal ±1 request/detik, atribusi
"Data provided by MangaDex", tanpa penggunaan komersial tanpa izin.

Gofile hanya untuk file yang kamu miliki haknya. Aplikasi tidak menyediakan
katalog streaming bajakan dan tidak melakukan scraping situs berhak cipta.
