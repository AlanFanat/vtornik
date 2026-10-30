import '../../core/constants.dart';
import '../../data/day_entry.dart';

/// Статистика одного тега. Только чтение, вся арифметика в геттерах.
class TagStat {
  const TagStat({
    required this.name,
    required this.days,
    required this.ratedDays,
    required this.ratingSum,
    required this.othersRatedDays,
    required this.othersRatingSum,
  });

  final String name;

  /// Всего дней с этим тегом (в том числе без оценки).
  final int days;

  /// Из них с оценкой, и сумма их оценок.
  final int ratedDays;
  final int ratingSum;

  /// Оценённые дни БЕЗ этого тега.
  final int othersRatedDays;
  final int othersRatingSum;

  /// Средняя оценка дней с тегом. null, если оценённых дней нет.
  double? get average => ratedDays == 0 ? null : ratingSum / ratedDays;

  /// Средняя оценка дней без тега. null, если таких дней нет.
  double? get othersAverage =>
      othersRatedDays == 0 ? null : othersRatingSum / othersRatedDays;

  /// Насколько дни с тегом лучше (+) или хуже (−) дней без него.
  /// null, если в какой-то из групп слишком мало данных.
  double? get impact {
    if (ratedDays < minTagDays || othersRatedDays < minTagDays) return null;
    return average! - othersAverage!;
  }
}

/// Накопитель для одного тега внутри [computeTagStats].
class _Acc {
  int days = 0;
  int ratedDays = 0;
  int ratingSum = 0;
}

/// Считает статистику по всем тегам за один проход по дням.
/// Сверху стоят теги с самым положительным влиянием, снизу с самым
/// отрицательным; теги без влияния (мало данных) идут в конце по числу дней.
List<TagStat> computeTagStats(Iterable<DayEntry> days) {
  var totalRatedDays = 0;
  var totalRatingSum = 0;
  final byTag = <String, _Acc>{};

  for (final day in days) {
    final rating = day.rating;
    if (rating != null) {
      totalRatedDays++;
      totalRatingSum += rating;
    }

    for (final tag in day.tags) {
      final acc = byTag.putIfAbsent(tag, _Acc.new);
      acc.days++;
      if (rating != null) {
        acc.ratedDays++;
        acc.ratingSum += rating;
      }
    }
  }

  final stats = [
    for (final entry in byTag.entries)
      TagStat(
        name: entry.key,
        days: entry.value.days,
        ratedDays: entry.value.ratedDays,
        ratingSum: entry.value.ratingSum,
        othersRatedDays: totalRatedDays - entry.value.ratedDays,
        othersRatingSum: totalRatingSum - entry.value.ratingSum,
      ),
  ];

  stats.sort((a, b) {
    final impactA = a.impact;
    final impactB = b.impact;
    if (impactA != null && impactB != null) return impactB.compareTo(impactA);
    if (impactA != null) return -1;
    if (impactB != null) return 1;

    final byDays = b.days.compareTo(a.days);
    return byDays != 0 ? byDays : a.name.compareTo(b.name);
  });

  return stats;
}