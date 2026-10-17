import 'package:flutter/material.dart';

import '../../data/day_entry.dart';
import 'day_card.dart';

/// Пока это лента прошлых дней; настоящая статистика появится позже.
class StatsPage extends StatelessWidget {
  const StatsPage({super.key, required this.entries});

  final Map<DateTime, DayEntry> entries;

  @override
  Widget build(BuildContext context) {
    // Новые дни сверху.
    final sortedEntries = entries.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    if (sortedEntries.isEmpty) {
      return const Center(
        child: Text(
          'Статистика появится позже',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(10),
      itemCount: sortedEntries.length,
      itemBuilder: (context, index) {
        final item = sortedEntries[index];
        return DayCard(date: item.key, entry: item.value);
      },
      separatorBuilder: (context, index) => const SizedBox(height: 4),
    );
  }
}
