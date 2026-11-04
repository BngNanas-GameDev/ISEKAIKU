/// URL gambar sampul yang disesuaikan dengan mode hemat data.
///
/// MangaDex menyediakan beberapa ukuran dengan nama berkas
/// `...<hash>.512.jpg`. Mode hemat data memakai `.256.jpg` supaya unduhan
/// jauh lebih kecil, terutama saat memakai kuota seluler.
String? coverUrlFor(String? url, {required bool dataSaver}) {
  if (url == null || url.isEmpty || !dataSaver) return url;

  final RegExp pattern = RegExp(
    r'\.(?:512|1024)\.(jpg|jpeg|png|webp)$',
    caseSensitive: false,
  );

  if (!pattern.hasMatch(url)) return url;
  return url.replaceFirstMapped(pattern, (match) => '.256.${match.group(1)}');
}
