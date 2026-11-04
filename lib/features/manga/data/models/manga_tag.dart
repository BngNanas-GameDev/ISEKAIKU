/// Tag MangaDex (genre/theme/format) untuk filter jelajah.
class MangaTag {
  const MangaTag({
    required this.id,
    required this.name,
    this.group = 'genre',
  });

  final String id;
  final String name;
  final String group;
}
