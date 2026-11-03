import 'package:freezed_annotation/freezed_annotation.dart';

part 'manga.freezed.dart';

/// Ringkasan manga hasil parsing MangaDex API v5.
@freezed
class Manga with _$Manga {
  const factory Manga({
    required String id,
    required String title,
    @Default('') String altTitle,
    @Default('') String description,
    @Default('ongoing') String status,
    @Default('') String year,
    @Default('safe') String contentRating,
    @Default(<String>[]) List<String> genres,
    String? coverUrl,
    @Default('') String author,
    @Default('ja') String originalLanguage,
    @Default(0) int follows,
  }) = _Manga;
}

/// Chapter hasil parsing feed MangaDex.
@freezed
class Chapter with _$Chapter {
  const factory Chapter({
    required String id,
    @Default('') String title,
    @Default('') String chapterNumber,
    @Default('') String volume,
    @Default('id') String language,
    @Default(0) int pages,
    DateTime? publishedAt,
    String? externalUrl,
  }) = _Chapter;
}

/// URL gambar sebuah chapter dari endpoint at-home.
@freezed
class ChapterPages with _$ChapterPages {
  const factory ChapterPages({
    required String chapterId,
    required String baseUrl,
    required String hash,
    @Default(<String>[]) List<String> data,
    @Default(<String>[]) List<String> dataSaver,
  }) = _ChapterPages;
}

extension ChapterPagesUrl on ChapterPages {
  /// [saver] = true memakai kualitas data-saver (lebih hemat kuota).
  List<String> urls({bool saver = false}) {
    final files = saver && dataSaver.isNotEmpty ? dataSaver : data;
    final folder = saver && dataSaver.isNotEmpty ? 'data-saver' : 'data';
    return files.map((f) => '$baseUrl/$folder/$hash/$f').toList();
  }
}
