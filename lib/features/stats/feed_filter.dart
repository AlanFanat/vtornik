import 'package:flutter/material.dart';
import '../../data/day_entry.dart';

@immutable
class FeedFilterState {
  const FeedFilterState({
    this.query = '',
    this.customFrom,
    this.customTo,
    this.selectedTags = const [],
    this.selectedRatings = const [],
    this.onlyUnrated = false,
  });

  final String query;
  final DateTime? customFrom;
  final DateTime? customTo;
  final List<String> selectedTags;
  final List<int> selectedRatings;
  final bool onlyUnrated;

  int get activeFilterCount {
    var count = 0;
    if (customFrom != null || customTo != null) count++;
    if (selectedTags.isNotEmpty) count++;
    if (selectedRatings.isNotEmpty || onlyUnrated) count++;
    return count;
  }

  bool get hasAnyFilter => query.trim().isNotEmpty || activeFilterCount > 0;

  FeedFilterState copyWith({
    String? query,
    DateTime? Function()? customFrom,
    DateTime? Function()? customTo,
    List<String>? selectedTags,
    List<int>? selectedRatings,
    bool? onlyUnrated,
  }) {
    return FeedFilterState(
      query: query ?? this.query,
      customFrom: customFrom != null ? customFrom() : this.customFrom,
      customTo: customTo != null ? customTo() : this.customTo,
      selectedTags: selectedTags ?? this.selectedTags,
      selectedRatings: selectedRatings ?? this.selectedRatings,
      onlyUnrated: onlyUnrated ?? this.onlyUnrated,
    );
  }
}

List<MapEntry<DateTime, DayEntry>> filterFeedEntries(
  Map<DateTime, DayEntry> entries,
  DateTimeRange? periodRange,
  FeedFilterState filter,
) {
  final trimmedQuery = filter.query.trim().toLowerCase();

  final hasCustomDates = filter.customFrom != null || filter.customTo != null;
  DateTime? rangeStart = periodRange?.start;
  DateTime? rangeEnd = periodRange?.end;

  if (hasCustomDates) {
    final from =
        filter.customFrom != null ? DateUtils.dateOnly(filter.customFrom!) : null;
    final to =
        filter.customTo != null ? DateUtils.dateOnly(filter.customTo!) : null;

    if (from != null && to != null && from.isAfter(to)) {
      rangeStart = to;
      rangeEnd = from;
    } else {
      rangeStart = from;
      rangeEnd = to;
    }
  }

  final hasRatingFilter = filter.selectedRatings.isNotEmpty || filter.onlyUnrated;
  final ratingSet = filter.selectedRatings.toSet();
  final result = <MapEntry<DateTime, DayEntry>>[];

  for (final item in entries.entries) {
    final date = DateUtils.dateOnly(item.key);
    final entry = item.value;

    if (rangeStart != null && date.isBefore(rangeStart)) continue;
    if (rangeEnd != null && date.isAfter(rangeEnd)) continue;

    if (hasRatingFilter) {
      final matchesRated =
          entry.rating != null && ratingSet.contains(entry.rating);
      final matchesUnrated = filter.onlyUnrated && entry.rating == null;
      if (!matchesRated && !matchesUnrated) continue;
    }

    if (filter.selectedTags.isNotEmpty) {
      final allMatch = filter.selectedTags.every(entry.tags.contains);
      if (!allMatch) continue;
    }

    if (trimmedQuery.isNotEmpty) {
      if (!entry.note.toLowerCase().contains(trimmedQuery)) continue;
    }

    result.add(item);
  }

  result.sort((a, b) => b.key.compareTo(a.key));
  return result;
}