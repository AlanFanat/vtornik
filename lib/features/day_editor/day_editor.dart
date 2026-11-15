import 'dart:async';
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../core/colors.dart';
import '../../core/constants.dart';
import '../../data/day_entry.dart';
import '../../widgets/day_title.dart';
import '../../widgets/section_title.dart';
import '../stats/day_card.dart';
import 'rating_row.dart';
import 'save_indicator.dart';
import 'tag_dialogs.dart';
import 'tags_section.dart';

class DayEditor extends StatefulWidget {
  const DayEditor({
    super.key,
    required this.selectedDate,
    required this.entry,
    required this.availableTags,
    required this.onAddTag,
    required this.onRenameTag,
    required this.onDeleteTag,
    required this.onChanged,
  });

  final DateTime selectedDate;
  final DayEntry? entry;
  final List<String> availableTags;
  final ValueChanged<String> onAddTag;
  final void Function(String from, String to) onRenameTag;
  final ValueChanged<String> onDeleteTag;
  final Future<bool> Function(DateTime date, DayEntry entry) onChanged;

  @override
  State<DayEditor> createState() => _DayEditorState();
}

class _DayEditorState extends State<DayEditor>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  bool _isEditing = false;

  /// 0.0 — компактная карточка (DayCard), 1.0 — форма редактирования.
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
    value: 0.0,
  );

  late final Animation<double> _cardOpacity =
      Tween<double>(begin: 1.0, end: 0.0).animate(
    CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.55)),
  );

  late final Animation<double> _formOpacity = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.45, 1.0),
  );

  double? _cardHeight;
  double? _formHeight;

  late int? _rating = widget.entry?.rating;
  late final Set<String> _tags = {...?widget.entry?.tags};
  late final TextEditingController _noteController = TextEditingController(
    text: widget.entry?.note ?? '',
  );
  Timer? _noteTimer;
  SaveStatus _status = SaveStatus.idle;
  Timer? _saveTimer;

  void _setSaveStatus(bool saved) {
    _saveTimer?.cancel();
    final status = saved ? SaveStatus.saved : SaveStatus.failed;
    setState(() => _status = status);

    _saveTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _status = SaveStatus.idle);
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _saveTimer?.cancel();
    _controller.dispose();

    if (_noteTimer?.isActive ?? false) {
      _noteTimer!.cancel();
      unawaited(widget.onChanged(widget.selectedDate, _currentEntry));
    }
    _noteController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      if (_noteTimer?.isActive ?? false) unawaited(_saveNow());
    }
  }

  @override
  void didUpdateWidget(covariant DayEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDate != widget.selectedDate) {
      if (_noteTimer?.isActive ?? false) {
        _noteTimer!.cancel();
        unawaited(widget.onChanged(oldWidget.selectedDate, _currentEntry));
      }
      _saveTimer?.cancel();
      _status = SaveStatus.idle;
      _isEditing = false;
      _controller.value = 0.0; // Мгновенный сброс при смене дня
      _cardHeight = null;
      _formHeight = null;
      _rating = widget.entry?.rating;
      _tags
        ..clear()
        ..addAll(widget.entry?.tags ?? const {});
      _noteController.text = widget.entry?.note ?? '';
    }
  }

  DayEntry get _currentEntry => DayEntry(
        rating: _rating,
        tags: {..._tags},
        note: _noteController.text.trim(),
      );

  void _openEditor() {
    if (_isEditing) return;
    setState(() => _isEditing = true);
    _controller.animateTo(1.0, curve: Curves.easeOutCubic);
  }

  Future<void> _closeEditor() async {
    if (!_isEditing) return;
    FocusScope.of(context).unfocus();
    if (_noteTimer?.isActive ?? false) {
      await _saveNow();
    }
    if (!mounted) return;
    setState(() => _isEditing = false);
    unawaited(_controller.animateTo(0.0, curve: Curves.easeOutCubic));
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  // ----- Автосохранение -----

  Future<void> _saveNow() async {
    _noteTimer?.cancel();
    final saved = await widget.onChanged(widget.selectedDate, _currentEntry);
    if (!mounted) return;
    _setSaveStatus(saved);
  }

  void _scheduleSave() {
    _noteTimer?.cancel();
    _noteTimer = Timer(noteSaveDelay, _saveNow);
  }

  // ----- Оценка -----

  void _selectRating(int rating) {
    setState(() => _rating = _rating == rating ? null : rating);
    unawaited(_saveNow());
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
    unawaited(_saveNow());
  }

  void _addTag(String name) {
    final existing = widget.availableTags
        .where((tag) => tag.toLowerCase() == name.toLowerCase())
        .firstOrNull;
    if (existing != null) {
      setState(() => _tags.add(existing));
      unawaited(_saveNow());
    } else {
      widget.onAddTag(name);
    }
  }

  void _createAndSelectTag(String name) {
    widget.onAddTag(name);
    setState(() => _tags.add(name));
    unawaited(_saveNow());
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

    widget.onRenameTag(tag, name);
    setState(() {
      if (_tags.remove(tag)) _tags.add(name);
    });
    unawaited(_saveNow());
  }

  Future<void> _deleteTag(String tag) async {
    final confirmed = await confirmDeleteTag(context, tag);
    if (!confirmed || !mounted) return;

    widget.onDeleteTag(tag);
    setState(() => _tags.remove(tag));
    unawaited(_saveNow());
  }

  // ----- Построение -----

  @override
  Widget build(BuildContext context) {
    // Оба слоя собираются заранее и не пересоздаются на каждом тике анимации.
    final cardLayer = _MeasureSize(
      onChange: (size) {
        if (_cardHeight != size.height) {
          setState(() => _cardHeight = size.height);
        }
      },
      child: DayCard(
        date: widget.selectedDate,
        entry: _currentEntry,
        maxNoteLines: null,
        showEditHint: true,
        onTap: _openEditor,
      ),
    );

    final formLayer = _MeasureSize(
      onChange: (size) {
        if (_formHeight != size.height) {
          setState(() => _formHeight = size.height);
        }
      },
      child: _buildForm(context),
    );

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;

        // Пока высоты не измерены на первом кадре, показываем активный виджет
        // без жёсткого ограничения высоты.
        final startH = _cardHeight ?? _formHeight;
        final endH = _formHeight ?? _cardHeight;
        final currentHeight = (startH != null && endH != null)
            ? lerpDouble(startH, endH, t)!.clamp(0.0, double.infinity)
            : null;

        final stack = Stack(
          alignment: Alignment.topCenter,
          children: [
            if (t < 1.0)
              IgnorePointer(
                ignoring: t > 0.5,
                child: FadeTransition(
                  opacity: _cardOpacity,
                  child: cardLayer,
                ),
              ),
            if (t > 0.0)
              IgnorePointer(
                ignoring: t < 0.5,
                child: FadeTransition(
                  opacity: _formOpacity,
                  child: formLayer,
                ),
              ),
          ],
        );

        if (currentHeight == null) return stack;

        return SizedBox(
          height: currentHeight,
          child: ClipRect(
            child: OverflowBox(
              alignment: Alignment.topCenter,
              minHeight: 0,
              maxHeight: double.infinity,
              child: stack,
            ),
          ),
        );
      },
    );
  }

  Widget _buildForm(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.cardBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: _closeEditor,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: DayTitle(date: widget.selectedDate)),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SaveIndicator(status: _status),
                    const SizedBox(width: 6),
                    // Стрелка синхронизирована с прогрессом раскрытия
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) => Transform.rotate(
                        angle: (1.0 - _controller.value) * 3.14159265,
                        child: child,
                      ),
                      child: Icon(
                        Icons.keyboard_arrow_up,
                        size: 25,
                        color: colors.text.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          RatingRow(selected: _rating, onSelected: _selectRating),
          const SizedBox(height: 10),
          TagsSection(
            availableTags: widget.availableTags,
            selectedTags: _tags,
            onToggle: _toggleTag,
            onAddTag: _addTag,
            onCreateAndSelectTag: _createAndSelectTag,
            onManageTag: _manageTag,
          ),
          const SizedBox(height: 10),
          const SectionTitle('Заметка'),
          const SizedBox(height: 4),
          TextField(
            controller: _noteController,
            onChanged: (_) => _scheduleSave(),
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
        ],
      ),
    );
  }
}

/// Отслеживает реальную высоту дочернего виджета после layout-фазы,
/// чтобы интерполировать высоту контейнера без искажения вёрстки.
class _MeasureSize extends SingleChildRenderObjectWidget {
  const _MeasureSize({required this.onChange, required super.child});

  final ValueChanged<Size> onChange;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _MeasureSizeRenderObject(onChange);

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _MeasureSizeRenderObject renderObject,
  ) {
    renderObject.onChange = onChange;
  }
}

class _MeasureSizeRenderObject extends RenderProxyBox {
  _MeasureSizeRenderObject(this.onChange);

  ValueChanged<Size> onChange;
  Size? _oldSize;

  @override
  void performLayout() {
    super.performLayout();
    final newSize = child?.size;
    if (newSize != null && _oldSize != newSize) {
      _oldSize = newSize;
      WidgetsBinding.instance.addPostFrameCallback((_) => onChange(newSize));
    }
  }
}