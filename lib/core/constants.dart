/// Теги, которые есть при первом запуске. Остальные пользователь добавляет сам.
const List<String> defaultTags = ['Работа', 'Френды', 'Школа'];

const int maxTagLength = 20;

/// Через сколько после последнего символа заметка сохраняется сама.
const Duration noteSaveDelay = Duration(milliseconds: 400);

/// Минимум оценённых дней в каждой группе, чтобы показывать влияние тега.
const int minTagDays = 3;

/// Разница оценок в пределах ±этого значения считается «нейтральной».
const double neutralImpact = 0.3;
