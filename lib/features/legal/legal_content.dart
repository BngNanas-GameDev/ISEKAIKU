/// Isi Syarat Layanan dan Kebijakan Privasi.
///
/// Teks ini tampil di aplikasi. Versi dinaikkan setiap kali isi berubah,
/// agar pengguna diminta menyetujui ulang.
library;

class LegalSection {
  const LegalSection({required this.title, required this.body});

  final String title;
  final String body;
}

class LegalDocument {
  const LegalDocument({
    required this.title,
    required this.updated,
    required this.sections,
  });

  final String title;
  final String updated;
  final List<LegalSection> sections;
}

abstract class LegalContent {
  const LegalContent._();

  /// Ganti saat isi legal berubah → pengguna menyetujui ulang.
  static const String version = '2026-11-04';

  static const String contactUrl =
      'https://github.com/BngNanas-GameDev/ISEKAIKU/issues';

  static const String contactLabel = 'GitHub Issues Isekaiku';

  static const String appName = 'Isekaiku';

  static const LegalDocument terms = LegalDocument(
    title: 'Syarat Layanan',
    updated: '4 November 2026',
    sections: <LegalSection>[
      LegalSection(
        title: '1. Tentang Isekaiku',
        body:
            'Isekaiku adalah aplikasi pembaca manga yang menampilkan katalog '
            'dari MangaDex melalui API resminya. Isekaiku tidak meng-host '
            'gambar atau chapter manga. Seluruh konten manga adalah milik '
            'pemegang hak cipta masing-masing dan disediakan oleh MangaDex.',
      ),
      LegalSection(
        title: '2. Kelayakan pengguna',
        body:
            'Kamu harus berusia minimal 13 tahun (atau usia dewasa menurut '
            'hukum di wilayahmu) untuk menggunakan aplikasi. Setelah masuk, '
            'kamu diminta mengisi tanggal lahir untuk menyesuaikan pengalaman '
            'sesuai usia. Tanggal lahir hanya bisa diisi **sekali** dan tidak '
            'dapat diubah. Fitur konten dewasa (rating Erotika) hanya untuk '
            'pengguna berusia 18 tahun ke atas.',
      ),
      LegalSection(
        title: '3. Akun',
        body:
            'Akun dibuat melalui login Google. Kamu bertanggung jawab menjaga '
            'akunmu. Kami dapat menangguhkan akun yang melanggar ketentuan, '
            'misalnya menyebarkan konten terlarang atau melakukan spam.',
      ),
      LegalSection(
        title: '4. Aturan forum',
        body:
            'Dilarang mengirim konten seksual eksplisit, promosi judi online, '
            'narkoba, tautan eksternal yang tidak diminta, ujaran kebencian, '
            'ancaman, doxing, atau spam. Konten yang dilaporkan dapat '
            'disembunyikan atau dihapus. Kamu dapat menghapus topik dan '
            'balasan milikmu sendiri.',
      ),
      LegalSection(
        title: '5. Konten 18+',
        body:
            'Konten rating Erotika hanya tersedia setelah kamu masuk dengan '
            'akun dan tanggal lahir yang tersimpan menunjukkan usia 18 tahun '
            'ke atas. Status ini dihitung ulang otomatis dan tidak memiliki '
            'masa berlaku. Rating pornografi tidak disediakan aplikasi.',
      ),
      LegalSection(
        title: '6. Penggunaan yang dilarang',
        body:
            'Dilarang menyalin, menjual, atau mendistribusikan ulang konten '
            'dari aplikasi ini secara melawan hukum; mengakali sistem '
            'verifikasi usia; menggunakan bot/scraper yang membebani server; '
            'atau mengunggah konten ilegal.',
      ),
      LegalSection(
        title: '7. Hak kekayaan intelektual',
        body:
            'Merek, antarmuka, dan kode Isekaiku milik pengembang. Katalog '
            'dan gambar manga tetap milik pemegang haknya dan MangaDex. '
            'Atribusi MangaDex ditampilkan di aplikasi.',
      ),
      LegalSection(
        title: '8. Batasan tanggung jawab',
        body:
            'Aplikasi disediakan apa adanya. Kami tidak menjamin ketersediaan '
            'layanan, kualitas terjemahan pihak ketiga, atau bahwa katalog '
            'bebas dari kesalahan. Kami tidak bertanggung jawab atas kerugian '
            'tidak langsung yang timbul dari penggunaan aplikasi, sejauh '
            'diizinkan hukum.',
      ),
      LegalSection(
        title: '9. Perubahan ketentuan',
        body:
            'Ketentuan dapat diperbarui. Jika ada perubahan penting, kamu akan '
            'diminta menyetujui versi terbaru sebelum melanjutkan.',
      ),
      LegalSection(
        title: '10. Kontak',
        body:
            'Pertanyaan, laporan, atau permintaan penghapusan data dapat '
            'dikirim melalui $contactLabel: $contactUrl.',
      ),
    ],
  );

  static const LegalDocument privacy = LegalDocument(
    title: 'Kebijakan Privasi',
    updated: '4 November 2026',
    sections: <LegalSection>[
      LegalSection(
        title: '1. Data yang kami proses',
        body:
            '• Akun: alamat email, nama tampilan, dan foto profil yang '
            'diberikan Google saat kamu masuk.\n'
            '• Pustaka: manga yang diikuti, riwayat baca, progres halaman, '
            'dan chapter yang sudah dibaca — hanya disinkronkan jika kamu '
            'masuk.\n'
            '• Forum: judul, isi topik/balasan, kategori, manga yang '
            'dilampirkan, serta waktu pembuatan.\n'
            '• Preferensi: bahasa chapter, mode reader, hemat data, setelan '
            'konten 18+, dan status persetujuan syarat — disimpan di '
            'perangkat.\n'
            '• Tanggal lahir: disimpan di profil setelah login, dipakai untuk '
            'mencocokkan fitur dengan usia. Hanya bisa diisi sekali dan tidak '
            'dapat diubah melalui aplikasi.',
      ),
      LegalSection(
        title: '2. Tujuan pemrosesan',
        body:
            'Menyediakan fitur baca dan sinkronisasi antar perangkat, '
            'menampilkan forum dan profil, menegakkan aturan komunitas, '
            'mencegah penyalahgunaan, serta memenuhi kewajiban hukum.',
      ),
      LegalSection(
        title: '3. Penyimpanan dan pihak ketiga',
        body:
            '• Supabase (region Singapura) menyimpan data akun, Pustaka, dan '
            'forum. Akses dilindungi Row Level Security.\n'
            '• Google menyediakan login OAuth (email, nama, foto).\n'
            '• MangaDex menyediakan katalog dan gambar; permintaan dikirim '
            'langsung ke API mereka.\n'
            '• Aplikasi tidak menampilkan iklan dan tidak menjual data.',
      ),
      LegalSection(
        title: '4. Data lokal',
        body:
            'Pustaka, riwayat, pengaturan, dan status verifikasi 18+ dapat '
            'dibaca tanpa akun dan disimpan di perangkat. Menghapus data '
            'aplikasi akan menghapus data lokal tersebut.',
      ),
      LegalSection(
        title: '5. Masa simpan',
        body:
            'Data akun dan forum disimpan selama akun aktif. Data yang kamu '
            'hapus (unfollow, hapus riwayat, hapus topik/balasan) ikut '
            'dihapus dari server pada sinkronisasi berikutnya. Akun beserta '
            'seluruh datanya dapat dihapus langsung lewat Akun → Hapus akun.',
      ),
      LegalSection(
        title: '6. Keamanan',
        body:
            'Kami memakai HTTPS, Row Level Security di database, dan '
            'penyimpanan sesi terenkripsi di perangkat. Tidak ada sistem yang '
            'sepenuhnya bebas risiko; laporkan masalah keamanan lewat kontak.',
      ),
      LegalSection(
        title: '7. Anak-anak',
        body:
            'Aplikasi tidak ditujukan untuk anak di bawah 13 tahun. Konten '
            'dewasa hanya untuk 18 tahun ke atas dan memerlukan akun. Jika '
            'kamu mengetahui akun anak di bawah umur mengakses konten 18+, '
            'laporkan agar kami tindak lanjuti.',
      ),
      LegalSection(
        title: '8. Hak kamu',
        body:
            'Kamu berhak mengakses, memperbaiki (bio), atau menghapus data '
            'milikmu. Akun dan seluruh data terkait dapat dihapus lewat '
            'Akun → Hapus akun. Tanggal lahir tidak dapat diubah sendiri; '
            'bila ada kesalahan pengisian, hubungi kami melalui '
            '$contactLabel dengan bukti yang sesuai.',
      ),
      LegalSection(
        title: '9. Perubahan kebijakan',
        body:
            'Kebijakan dapat diperbarui. Perubahan penting akan ditampilkan '
            'dan kamu diminta menyetujui ulang.',
      ),
      LegalSection(
        title: '10. Kontak',
        body: 'Pertanyaan privasi: $contactLabel — $contactUrl.',
      ),
    ],
  );
}
