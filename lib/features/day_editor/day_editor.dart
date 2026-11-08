import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../core/constants.dart';
import '../../core/date_format.dart';
import '../../data/day_entry.dart';
import '../../widgets/section_title.dart';
import 'rating_row.dart';
import 'save_indicator.dart';
import 'tag_dialogs.dart';
import 'tags_section.dart';

/// Форма дня. Работает в двух режимах:
///  * обычный (по умолчанию): каждое изменение сразу сохраняется;
///  * правка готовой записи ([onDraftChanged] задан): изменения копятся
///    в черновике и применяются, только когда родитель нажмёт «Готово».
class DayEditor extends StatefulWidget {
  const DayEditor({
    super.key,
    required this.selectedDate,
    required this.entry,
    required this.availableTags,
    required this.onAddTag,
    required this.onRenameTag,
    required this.onDeleteTag,
    required this.onDone,
    required this.onChanged,
    this.onCancel,
    this.onDraftChanged,
  });

  final DateTime selectedDate;
  final DayEntry? entry;
  final List<String> availableTags;
  final ValueChanged<String> onAddTag;
  final void Function(String from, String to) onRenameTag;
  final ValueChanged<String> onDeleteTag;

  /// «Готово»: свернуть форму в карточку. null — кнопки нет.
  final VoidCallback? onDone;

  /// «Отмена» в режиме правки: выбросить черновик. null — кнопки нет.
  final VoidCallback? onCancel;

  /// Если задан, форма работает как черновик и ничего не сохраняет сама.
  final ValueChanged<DayEntry>? onDraftChanged;

  /// Вызывается при каждом изменении дня (в обычном режиме). Возвращает true,
  /// если запись удалось сохранить на устройство.
  final Future<bool> Function(DateTime date, DayEntry entry) onChanged;

  @override
  State<DayEditor> createState() => _DayEditorState();
}

class _DayEditorState extends State<DayEditor> with WidgetsBindingObserver {
  late int? _rating = widget.entry?.rating;
  late final Set<String> _tags = {...?widget.entry?.tags};
  late final TextEditingController _noteController = TextEditingController(
    text: widget.entry?.note ?? '',
  );

  Timer? _noteTimer;
  SaveStatus _status = SaveStatus.idle;

  bool get _draftMode => widget.onDraftChanged != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    // Заметку не успели сохранить (сменили день за доли секунды) — сохраняем сейчас.
    // В режиме правки таймера нет, так что черновик сюда не попадает.
    if (_noteTimer?.isActive ?? false) {
      _noteTimer!.cancel();
      unawaited(widget.onChanged(widget.selectedDate, _currentEntry));
    }

    _noteController.dispose();
    super.dispose();
  }

  /// Если приложение уходит в фон, не ждём таймер.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      if (_noteTimer?.isActive ?? false) unawaited(_saveNow());
    }
  }

  DayEntry get _currentEntry => DayEntry(
    rating: _rating,
    tags: {..._tags},
    note: _noteController.text.trim(),
  );

  void _showMessage(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  // ----- Сохранение -----

  Future<void> _saveNow() async {
    _noteTimer?.cancel();

    final saved = await widget.onChanged(widget.selectedDate, _currentEntry);
    if (!mounted) return;

    setState(() => _status = saved ? SaveStatus.saved : SaveStatus.failed);
  }

  /// Заметку сохраняем не на каждую букву, а когда пользователь на миг замолчал.
  void _scheduleSave() {
    _noteTimer?.cancel();
    _noteTimer = Timer(noteSaveDelay, _saveNow);
  }

  /// Что-то изменилось. В режиме правки отдаём черновик наверх,
  /// в обычном режиме сохраняем сразу.
  void _changed() {
    if (_draftMode) {
      setState(() => _status = SaveStatus.draft);
      widget.onDraftChanged!(_currentEntry);
    } else {
      unawaited(_saveNow());
    }
  }

  void _noteChanged() {
    if (_draftMode) {
      _changed();
    } else {
      _scheduleSave();
    }
  }

  /// «Готово»: в обычном режиме сначала дописываем сохранение,
  /// в режиме правки применять черновик будет родитель.
  Future<void> _done() async {
    FocusScope.of(context).unfocus();
    if (!_draftMode) await _saveNow(); // не ждём таймер заметки
    widget.onDone?.call();
  }

  // ----- Оценка -----

  /// Повторное нажатие на выбранную оценку снимает её.
  void _selectRating(int rating) {
    setState(() => _rating = _rating == rating ? null : rating);
    _changed();
  }

  // ----- Теги -----

  void _toggleTag(String tag, bool selected) {
    setState(() {
      if (selected) {
        _tags.add(tag);
      } else {
        _tags.remove(tag);
      }
    });
    _changed();
  }

  Future<void> _addTag() async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) =>
          const TagNameDialog(title: 'Новый тег', confirmLabel: 'Добавить'),
    );
    if (name == null || !mounted) return;

    // Такой тег уже есть (без учёта регистра) — просто выбираем его.
    final existing = widget.availableTags
        .where((tag) => tag.toLowerCase() == name.toLowerCase())
        .firstOrNull;
    if (existing != null) {
      // Дубликат — выбираем существующий тег для текущего дня.
      setState(() => _tags.add(existing));
      _changed();
    } else {
      // Новый тег — только добавляем в общий список, без автовыбора.
      widget.onAddTag(name);
    }
  }

  Future<void> _manageTag(String tag) async {
    final action = await showTagActionsSheet(context, tag);
    if (action == null || !mounted) return;

    switch (action) {
      case TagAction.rename:
        await _renameTag(tag);
      case TagAction.delete:
        await _deleteTag(tag);
    }
  }

  Future<void> _renameTag(String tag) async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => TagNameDialog(
        title: 'Переименовать тег',
        confirmLabel: 'Сохранить',
        initial: tag,
      ),
    );
    if (name == null || !mounted || name == tag) return;

    final clash = widget.availableTags.any(
      (other) => other != tag && other.toLowerCase() == name.toLowerCase(),
    );
    if (clash) {
      _showMessage('Тег «$name» уже есть');
      return;
    }

    // Тег меняется и в общем списке, и во всех прошлых днях
    // (в том числе в режиме правки: переименование не часть черновика).
    widget.onRenameTag(tag, name);
    setState(() {
      if (_tags.remove(tag)) _tags.add(name);
    });
    _changed();
  }

  Future<void> _deleteTag(String tag) async {
    final confirmed = await confirmDeleteTag(context, tag);
    if (!confirmed || !mounted) return;

    widget.onDeleteTag(tag);
    setState(() => _tags.remove(tag));
    _changed();
  }

  // ----- Экран -----

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    // В режиме правки «Готово» есть всегда. В обычном режиме только когда
    // в дне уже что-то записано, иначе сворачивать нечего.
    final showDone =
        widget.onDone != null && (_draftMode || !_currentEntry.isEmpty);
    final showCancel = widget.onCancel != null;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  formatDate(widget.selectedDate),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: colors.text,
                  ),
                ),
              ),
              SaveIndicator(status: _status),
            ],
          ),
          const SizedBox(height: 8),
          RatingRow(selected: _rating, onSelected: _selectRating),
          const SizedBox(height: 10),
          TagsSection(
            availableTags: widget.availableTags,
            selectedTags: _tags,
            onToggle: _toggleTag,
            onAdd: _addTag,
            onManage: _manageTag,
          ),
          const SizedBox(height: 10),
          const SectionTitle('Заметка'),
          const SizedBox(height: 4),
          TextField(
            controller: _noteController,
            onChanged: (_) => _noteChanged(),
            maxLines: 4,
            style: TextStyle(color: colors.text),
            decoration: InputDecoration(
              hintText: 'Что запомнилось в этот день?',
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
              filled: true,
              fillColor: colors.inputFill,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          if (showDone || showCancel) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (showCancel)
                  TextButton(
                    onPressed: widget.onCancel,
                    child: const Text('Отмена'),
                  ),
                if (showCancel && showDone) const SizedBox(width: 8),
                if (showDone)
                  FilledButton(onPressed: _done, child: const Text('Готово')),
              ],
            ),
          ],
        ],
      ),
    );
  }
}