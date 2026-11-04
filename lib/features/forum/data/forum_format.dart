/// Pemformat waktu ringkas untuk forum.
abstract class ForumFormat {
  const ForumFormat._();

  /// Contoh: "baru saja", "5 mnt", "3 jam", "2 hr", "12 Nov".
  static String relative(DateTime time, {DateTime? now}) {
    final current = now ?? DateTime.now();
    final difference = current.difference(time);

    if (difference.isNegative || difference.inSeconds < 60) {
      return 'baru saja';
    }
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} mnt';
    }
    if (difference.inHours < 24) {
      return '${difference.inHours} jam';
    }
    if (difference.inDays < 30) {
      return '${difference.inDays} hr';
    }

    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    final local = time.toLocal();
    final label = '${local.day} ${months[local.month - 1]}';
    return local.year == current.year ? label : '$label ${local.year}';
  }

  /// Inisial untuk avatar: "Budi Santoso" → "BS".
  static String initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList(growable: false);
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first[0].toUpperCase();
    }
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}
