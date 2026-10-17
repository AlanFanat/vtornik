import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/colors.dart';
import '../../widgets/section_title.dart';
import 'restore_dialog.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
    required this.isDarkTheme,
    required this.onDarkThemeChanged,
    required this.onBackupText,
    required this.onRestore,
  });

  final bool isDarkTheme;
  final ValueChanged<bool> onDarkThemeChanged;

  /// Возвращает текст резервной копии.
  final String Function() onBackupText;

  /// Восстанавливает данные из текста. Возвращает ошибку или null.
  final String? Function(String text) onRestore;

  void _showMessage(BuildContext context, String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _copyBackup(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: onBackupText()));
    if (!context.mounted) return;

    _showMessage(
      context,
      'Скопировано. Вставьте в заметки или в «Избранное» мессенджера.',
    );
  }

  Future<void> _restoreBackup(BuildContext context) async {
    final text = await showDialog<String>(
      context: context,
      builder: (_) => const RestoreDialog(),
    );
    if (text == null || !context.mounted) return;

    _showMessage(context, onRestore(text) ?? 'Данные восстановлены');
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return ListView(
      padding: const EdgeInsets.all(10),
      children: [
        PageTitle('Настройки'),
        const SizedBox(height: 12),

        _SettingsCard(
          child: SwitchListTile(
            secondary: Icon(Icons.dark_mode_outlined, color: colors.text),
            title: Text('Тёмная тема', style: TextStyle(color: colors.text)),
            value: isDarkTheme,
            onChanged: onDarkThemeChanged,
            activeTrackColor: accentColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          ),
        ),

        const SizedBox(height: 16),
        const SectionTitle('Резервная копия'),
        const SizedBox(height: 6),

        _SettingsCard(
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.copy_outlined, color: colors.text),
                title: Text(
                  'Скопировать данные',
                  style: TextStyle(color: colors.text),
                ),
                subtitle: const Text('Все дни и теги — в буфер обмена'),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                onTap: () => _copyBackup(context),
              ),
              Divider(height: 1, color: colors.cardBorder),
              ListTile(
                leading: Icon(Icons.restore_outlined, color: colors.text),
                title: Text(
                  'Восстановить из копии',
                  style: TextStyle(color: colors.text),
                ),
                subtitle: const Text('Вставьте ранее скопированный текст'),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                onTap: () => _restoreBackup(context),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Карточка настроек. Material (а не Container), чтобы была видна рябь нажатия.
class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Material(
      color: colors.card,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: colors.cardBorder),
      ),
      child: child,
    );
  }
}
