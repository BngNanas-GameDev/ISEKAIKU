import 'package:flutter_test/flutter_test.dart';
import 'package:isekaiku/features/manga/data/chapter_range.dart';
import 'package:isekaiku/features/manga/data/models/manga.dart';

Chapter _chapter(String number) => Chapter(id: 'c$number', chapterNumber: number);

void main() {
  group('ChapterRange.from', () {
    test('rentang dihitung dari nomor terkecil dan terbesar', () {
      final range = ChapterRange.from(
        <Chapter>[_chapter('3'), _chapter('1'), _chapter('10')],
        'ongoing',
      );

      expect(range, isNotNull);
      expect(range!.first, 1);
      expect(range.last, 10);
      expect(range.label, 'Ch. 1–10');
      expect(range.complete, isFalse);
    });

    test('selesai + 1..N tanpa bolong dianggap lengkap', () {
      final chapters = List<Chapter>.generate(12, (i) => _chapter('${i + 1}'));

      final range = ChapterRange.from(chapters, 'completed');

      expect(range!.complete, isTrue);
      expect(range.label, 'Ch. 1–12');
    });

    test('selesai tetapi ada nomor bolong tidak dianggap lengkap', () {
      final range = ChapterRange.from(
        <Chapter>[_chapter('1'), _chapter('2'), _chapter('4')],
        'completed',
      );

      expect(range!.complete, isFalse);
    });

    test('berjalan walau lengkap tetap tidak dianggap lengkap', () {
      final chapters = List<Chapter>.generate(5, (i) => _chapter('${i + 1}'));

      final range = ChapterRange.from(chapters, 'ongoing');

      expect(range!.complete, isFalse);
    });

    test('mulai dari chapter 2 tidak dianggap lengkap', () {
      final range = ChapterRange.from(
        <Chapter>[_chapter('2'), _chapter('3'), _chapter('4')],
        'completed',
      );

      expect(range!.complete, isFalse);
      expect(range.label, 'Ch. 2–4');
    });

    test('nomor pecahan tetap tampil apa adanya', () {
      final range = ChapterRange.from(
        <Chapter>[_chapter('1'), _chapter('86'), _chapter('86.1')],
        'ongoing',
      );

      expect(range!.last, 86.1);
      expect(range.label, 'Ch. 1–86.1');
    });

    test('chapter tanpa nomor diabaikan', () {
      final range = ChapterRange.from(
        <Chapter>[_chapter(''), _chapter('1')],
        'completed',
      );

      expect(range!.label, 'Ch. 1–1');
      expect(range.complete, isTrue);
    });

    test('tanpa nomor valid mengembalikan null', () {
      final range = ChapterRange.from(<Chapter>[_chapter('')], 'completed');

      expect(range, isNull);
    });
  });
}
