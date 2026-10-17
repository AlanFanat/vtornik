import 'day_entry.dart';

/// Содержимое резервной копии.
class BackupData {
  const BackupData({required this.tags, required this.entries});

  final List<String> tags;
  final Map<DateTime, DayEntry> entries;
}
