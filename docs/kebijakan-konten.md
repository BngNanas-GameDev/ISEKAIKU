# Kebijakan Konten 18+ (Erotika)

Berlaku untuk katalog manga (MangaDex) dan forum komunitas Isekaiku.

## 1. Ambang usia: 18 tahun

| Dasar | Keterangan |
|---|---|
| Hukum Indonesia | UU No. 23 Tahun 2002 tentang Perlindungan Anak: anak adalah orang yang **belum berusia 18 tahun**. |
| Google Play / IARC | Konten seksual grafis mendapat rating **18+** (IARC 18+, PEGI 18, ESRB *Adults Only*). Google Play memblokir aplikasi 18+ dari pencarian/unduhan pengguna yang terdeteksi **di bawah 18 tahun** di Indonesia. |
| Panduan *neutral age screen* | Google Play meminta input tanggal lahir **bebas** (tidak diisi otomatis dan tidak mengungkap usia yang dibutuhkan). |

Aplikasi memakai **18 tahun**, bukan 21.

## 2. Aturan katalog

1. **Bawaan mati.** Tanpa verifikasi, aplikasi hanya meminta rating `safe` dan
   `suggestive` ke MangaDex.
2. **Aktif hanya lewat verifikasi tanggal lahir** di
   **Pustaka → ⋮ → Konten 18+ (Erotika)**.
3. **Hanya `erotica` yang dibuka.** Rating `pornographic` **tidak pernah**
   diminta ke MangaDex dan tidak ditampilkan aplikasi.
4. **Verifikasi berlaku 30 hari**, lalu otomatis mati dan harus diulang.
5. **Tanggal lahir tidak disimpan** dan tidak dikirim ke server. Yang
   disimpan hanya status verifikasi + waktunya, di perangkat.
6. **Bisa dimatikan kapan saja**; status dan waktu verifikasi langsung
   dihapus.
7. Judul erotika diberi lencana **18+** di kartu dan halaman detail.

## 3. Aturan forum (UGC)

1. Forum dapat **dibaca tanpa login**; menulis wajib login Google.
2. Konten seksual eksplisit **dilarang** di forum. Trigger server menolak
   tautan eksternal, promosi judi, dan narkoba; moderasi manual dapat
   menyembunyikan topik/balasan.
3. Setiap topik/balasan bisa **dilaporkan**; pemilik dapat menghapus
   miliknya sendiri.
4. Konten yang dilaporkan ditinjau dan dapat disembunyikan
   (`is_hidden = true`) dari dashboard Supabase.

## 4. Kewajiban saat rilis di Google Play

- Isi kuesioner rating IARC dengan jujur. Aplikasi yang memuat erotika
  kemungkinan mendapat rating **18+**.
- Jika target audiens hanya 18+, aktifkan **Restrict Minor Access** di Play
  Console.
- Jangan menaruh konten 18+ di tangkapan layar/ikon/deskripsi toko.
- Kebijakan Google Play melarang **pornografi**; karena itu rating
  `pornographic` tidak pernah diminta aplikasi.
- Sediakan kebijakan privasi yang menyebut pemrosesan tanggal lahir (di sini:
  tidak disimpan) dan data akun/forum.

## 5. Rujukan

- Google Play — Age-Restricted Content and Functionality:
  <https://support.google.com/googleplay/android-developer/answer/16302250>
- Google Play — User Generated Content (filter konten seksual insidental,
  minimal dua aksi pengguna, neutral age screen):
  <https://support.google.com/googleplay/android-developer/answer/9876937>
- Google Play — Target audience & neutral age screen:
  <https://support.google.com/googleplay/android-developer/answer/9867159>
- Google Play — Content ratings (IARC 18+):
  <https://support.google.com/googleplay/android-developer/answer/9859655>
- UU No. 23 Tahun 2002 tentang Perlindungan Anak (definisi anak < 18 tahun).
