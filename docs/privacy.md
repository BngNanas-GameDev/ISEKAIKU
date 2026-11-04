# Kebijakan Privasi Isekaiku

Terakhir diperbarui: 4 November 2026

Isekaiku adalah aplikasi pembaca manga yang menampilkan katalog dari
MangaDex. Kebijakan ini menjelaskan data yang diproses dan hak kamu.

## 1. Data yang kami proses

- **Akun**: alamat email, nama tampilan, dan foto profil dari Google saat
  kamu masuk.
- **Pustaka**: manga diikuti, riwayat baca, progres halaman, dan chapter
  yang sudah dibaca (disinkronkan hanya jika kamu masuk).
- **Forum**: judul, isi topik/balasan, kategori, manga yang dilampirkan,
  serta waktu pembuatan.
- **Tanggal lahir**: disimpan di profil setelah login, dipakai untuk
  menyesuaikan fitur dengan usia. Hanya bisa diisi sekali dan tidak dapat
  diubah melalui aplikasi.
- **Preferensi**: bahasa chapter, mode reader, hemat data, setelan konten
  18+, dan status persetujuan — disimpan di perangkat.

## 2. Tujuan

Menyediakan fitur baca dan sinkronisasi, forum dan profil, menegakkan aturan
komunitas, mencegah penyalahgunaan, dan memenuhi kewajiban hukum.

## 3. Penyimpanan dan pihak ketiga

- **Supabase** (region Singapura) menyimpan data akun, Pustaka, dan forum,
  dilindungi Row Level Security.
- **Google** menyediakan login OAuth (email, nama, foto).
- **MangaDex** menyediakan katalog dan gambar; permintaan dikirim langsung
  ke API mereka.
- Aplikasi tidak menampilkan iklan dan tidak menjual data.

## 4. Data lokal

Pustaka, riwayat, pengaturan, dan status verifikasi disimpan di perangkat dan
dipisah per akun. Menghapus data aplikasi akan menghapus data lokal tersebut.

## 5. Masa simpan

Data akun dan forum disimpan selama akun aktif. Data yang kamu hapus
(unfollow, hapus riwayat, hapus topik/balasan) ikut dihapus dari server pada
sinkronisasi berikutnya. Akun beserta seluruh datanya dapat dihapus langsung
lewat **Akun → Hapus akun**.

## 6. Keamanan

Kami memakai HTTPS, Row Level Security di database, dan penyimpanan sesi
terenkripsi di perangkat.

## 7. Anak-anak

Aplikasi tidak ditujukan untuk anak di bawah 13 tahun. Konten dewasa hanya
untuk 18 tahun ke atas dan memerlukan akun.

## 8. Hak kamu

Kamu berhak mengakses, memperbaiki (bio), atau menghapus data milikmu.
Akun dan seluruh data terkait dapat dihapus lewat **Akun → Hapus akun**.
Tanggal lahir tidak dapat diubah sendiri; bila ada kesalahan pengisian,
hubungi kami dengan bukti yang sesuai.

## 9. Perubahan

Kebijakan dapat diperbarui. Perubahan penting akan ditampilkan di aplikasi
dan kamu diminta menyetujui ulang.

## 10. Kontak

Laporkan pertanyaan atau permintaan data melalui:
<https://github.com/BngNanas-GameDev/ISEKAIKU/issues>
