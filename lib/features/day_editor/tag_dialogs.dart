import 'package:flutter/material.dart';

import '../../core/constants.dart';

enum TagAction { rename, delete }

/// Нижняя панель с действиями над тегом. Возвращает выбранное действие или null.
Future<TagAction?> showTagActionsSheet(BuildContext context, String tag) {
  return showModalBottomSheet<TagAction>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              tag,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 4),
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Переименовать'),
            onTap: () => Navigator.pop(context, TagAction.rename),
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('Удалить'),
            onTap: () => Navigator.pop(context, TagAction.delete),
          ),
        ],
      ),
    ),
  );
}

/// Спрашивает, точно ли удалить тег. Возвращает true только при подтверждении.
Future<bool> confirmDeleteTag(BuildContext context, String tag) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Удалить тег «$tag»?'),
      content: const Text('Он пропадёт и из всех прошлых дней.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Отмена'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Удалить'),
        ),
      ],
    ),
  );
  return confirmed == true;
}

/// Диалог с названием тега: и для нового, и для переименования.
/// Возвращает название или null.
class TagNameDialog extends StatefulWidget {
  const TagNameDialog({
    super.key,
    required this.title,
    required this.confirmLabel,
    this.initial = '',
  });

  final String title;
  final String confirmLabel;
  final String initial;

  @override
  State<TagNameDialog> createState() => _TagNameDialogState();
}

class _TagNameDialogState extends State<TagNameDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial,
  )..selection = TextSelection.collapsed(offset: widget.initial.length);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    // Пустое название не принимаем.
    if (name.isNotEmpty) Navigator.pop(context, name);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: maxTagLength,
        textCapitalization: TextCapitalization.sentences,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
        decoration: const InputDecoration(hintText: 'Например, Спорт'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        TextButton(onPressed: _submit, child: Text(widget.confirmLabel)),
      ],
    );
  }
}
