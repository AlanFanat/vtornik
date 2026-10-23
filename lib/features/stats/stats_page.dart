import 'package:flutter/material.dart';

import '../../data/day_entry.dart';
import '../../widgets/section_title.dart';
import 'day_card.dart';

/// Пока это лента прошлых дней; настоящая статистика появится позже.
class StatsPage extends StatelessWidget {
  const StatsPage({super.key, required this.entries, required this.onDaySelected});

  final Map<DateTime, DayEntry> entries;

  final ValueChanged<DateTime> onDaySelected;

  @override
  Widget build(BuildContext context) {
    // Новые дни сверху.
    final sortedEntries = entries.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    // Записей нет: прокручивать нечего, заголовок просто стоит сверху.
    if (sortedEntries.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageTitle('Статистика'),
            Expanded(
              child: Center(
                child: Text(
                  'Статистика появится позже',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(10),
      // +1: нулевой элемент списка — заголовок, он прокручивается вместе с днями.
      itemCount: sortedEntries.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          // 4 px даёт разделитель, ещё 2 — чтобы вышло 6, как в настройках и под заголвком Календарь.
          return const Padding(
            padding: EdgeInsets.only(bottom: 2),
            child: PageTitle('Статистика'),
          );
        }

        final item = sortedEntries[index - 1];
        return DayCard(
          date: item.key,
          entry: item.value,
          onTap: () => onDaySelected(item.key),
        );
      },
      separatorBuilder: (context, index) => const SizedBox(height: 4),
    );
  }
}
