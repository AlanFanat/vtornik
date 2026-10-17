import 'package:flutter/foundation.dart';

/// Запись об одном дне. Неизменяемая: чтобы изменить день, создаём новую.
/// Оценки может не быть: запись с одними тегами или заметкой тоже сохраняется.
@immutable
class DayEntry {
  const DayEntry({this.rating, this.tags = const {}, this.note = ''});

  final int? rating;
  final Set<String> tags;
  final String note;

  /// В пустой записи нет ничего, её не храним.
  bool get isEmpty => rating == null && tags.isEmpty && note.isEmpty;

  DayEntry withTags(Set<String> tags) {
    return DayEntry(rating: rating, tags: tags, note: note);
  }

  Map<String, dynamic> toJson() => {
    if (rating != null) 'rating': rating,
    'tags': tags.toList()..sort(),
    'note': note,
  };

  factory DayEntry.fromJson(Map<String, dynamic> json) {
    final rating = json['rating'] as int?;

    return DayEntry(
      // Защита от испорченных данных: оценка всегда в пределах 1..10.
      rating: rating?.clamp(1, 10).toInt(),
      tags: {...((json['tags'] as List<dynamic>?) ?? const []).cast<String>()},
      note: (json['note'] as String?) ?? '',
    );
  }
}
