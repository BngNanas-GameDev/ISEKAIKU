import 'models/manga.dart';

/// Ringkasan ketersediaan chapter: rentang nomor + status lengkap.
class ChapterRange {
  const ChapterRange({
    required this.first,
    required this.last,
    required this.complete,
  });

  /// Nomor chapter terkecil yang tersedia (bisa pecahan, mis. 86.1).
  final double first;

  /// Nomor chapter terbesar yang tersedia.
  final double last;

  /// True bila seri sudah tamat dan chapter 1..N tersedia tanpa bolong.
  final bool complete;

  String get label => 'Ch. ${_fmt(first)}–${_fmt(last)}';

  /// `null` bila tidak ada nomor chapter yang valid.
  static ChapterRange? from(List<Chapter> chapters, String status) {
    final numbers = <double>[];
    for (final chapter in chapters) {
      final value = double.tryParse(chapter.chapterNumber);
      if (value != null) numbers.add(value);
    }
    if (numbers.isEmpty) return null;

    numbers.sort();
    final first = numbers.first;
    final last = numbers.last;

    final ints = numbers.map((n) => n.floor()).toSet();
    var contiguous = true;
    for (var i = 1; i <= last.floor(); i++) {
      if (!ints.contains(i)) {
        contiguous = false;
        break;
      }
    }

    return ChapterRange(
      first: first,
      last: last,
      complete: status == 'completed' && contiguous && first <= 1,
    );
  }

  static String _fmt(double value) =>
      value == value.roundToDouble() ? value.toInt().toString() : '$value';
}
