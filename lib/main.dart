import 'package:flutter/material.dart';

// Светлая тема: цвета вынесены в константы, чтобы их было легко менять.
const Color mainColor = Color(0xFFF4F4F7); // фон экрана
const Color cardColor = Color(0xFFFFFFFF); // фон карточки
const Color cardBorderColor = Color(0xFFE3E3E8); // рамка карточки
const Color surfaceColor = Color(0xFFE9E9EE); // ячейки, чипы, кружки оценок
const Color inputFillColor = Color(0xFFF0F0F4); // фон поля заметки
const Color textColor = Color(0xFF18181C); // основной текст
const Color accentColor = Color(0xFFE5B84B); // акцент (жёлтый)

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: mainColor,
        brightness: Brightness.light,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: accentColor,
          brightness: Brightness.light,
        ),
      ),
      home: const HomePage(),
    );
  }
}

//----PAGES----

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const MonthCalendar(),

              const SizedBox(height: 12),

              const DayEditor(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: inputFillColor,
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.calendar_month),
            label: 'Календарь',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart),
            label: 'Статистика',
          ),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Настройки'),
        ],
      ),
    );
  }
}

//----WIDGETS----

class MonthCalendar extends StatelessWidget {
  const MonthCalendar({super.key});

  @override
  Widget build(BuildContext context) {
    // Пока показываем октябрь 2026 года.
    const year = 2026;
    const month = 10;

    final firstDay = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;

    // В Dart неделя начинается с понедельника:
    // Monday = 1, Sunday = 7.
    final startOffset = firstDay.weekday - 1;

    // Количество ячеек: пустые места + дни месяца.
    final totalCells = startOffset + daysInMonth;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(
          child: Text(
            'Октябрь 2026',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Названия дней недели.
        Row(
          children: ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'].map((day) {
            return Expanded(
              child: Center(
                child: Text(
                  day,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 6),

        // Сетка календаря.
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: totalCells,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
            childAspectRatio: 1.4,
          ),
          itemBuilder: (context, index) {
            // Пустые ячейки перед первым днём.
            if (index < startOffset) {
              return const SizedBox.shrink();
            }

            final day = index - startOffset + 1;

            return Container(
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                '$day',
                style: const TextStyle(color: textColor, fontSize: 14),
              ),
            );
          },
        ),
      ],
    );
  }
}

class DayEditor extends StatefulWidget {
  const DayEditor({super.key});

  @override
  State<DayEditor> createState() => _DayEditorState();
}

class _DayEditorState extends State<DayEditor> {
  int? selectedRating;

  final Set<String> selectedTags = {};

  final List<String> tags = [
    'Продуктивный',
    'Отдых',
    'Друзья',
    'Семья',
    'Спорт',
    'Работа',
    'Путешествие',
    'Стресс',
  ];

  final TextEditingController noteController = TextEditingController();

  Color colorForRating(int rating) {
    if (rating <= 2) return const Color(0xFFE05252);
    if (rating <= 4) return const Color(0xFFE58B45);
    if (rating <= 6) return const Color(0xFFE0BC45);
    if (rating <= 8) return const Color(0xFF8ABF65);
    return const Color(0xFF35A866);
  }

  @override
  void dispose() {
    noteController.dispose();
    super.dispose();
  }

  void saveDay() {
    if (selectedRating == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Сначала поставь оценку дню')),
      );
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('День сохранён!')));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cardBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Оценка дня',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),

          // const SizedBox(height: 2),

          // const Text(
          //   'Как прошёл твой день?',
          //   style: TextStyle(color: Colors.grey, fontSize: 14),
          // ),
          const SizedBox(height: 6),

          Wrap(
            spacing: 4,
            runSpacing: 8,
            children: List.generate(10, (index) {
              final rating = index + 1;
              final isSelected = selectedRating == rating;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedRating = rating;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: isSelected ? colorForRating(rating) : surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? colorForRating(rating)
                          : Colors.transparent,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$rating',
                    style: TextStyle(
                      color: isSelected ? Colors.black : textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 6),

          // ТЕГИ
          const Text(
            'Теги дня',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),

          const SizedBox(height: 2),

          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: tags.map((tag) {
              final isSelected = selectedTags.contains(tag);

              return FilterChip(
                label: Text(
                  tag,
                  style: const TextStyle(fontSize: 12, color: textColor),
                ),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      selectedTags.add(tag);
                    } else {
                      selectedTags.remove(tag);
                    }
                  });
                },
                selectedColor: accentColor,
                checkmarkColor: Colors.black,
                backgroundColor: surfaceColor,
                showCheckmark: false,
                visualDensity: const VisualDensity(
                  horizontal: -3,
                  vertical: -3,
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                side: BorderSide.none,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 6),

          // ЗАМЕТКА
          const Text(
            'Заметка',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),

          const SizedBox(height: 4),

          TextField(
            controller: noteController,
            maxLines: 4,
            style: const TextStyle(color: textColor),
            decoration: InputDecoration(
              hintText: 'Что хорошего произошло сегодня?',
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
              filled: true,
              fillColor: inputFillColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 10),

          // КНОПКА СОХРАНЕНИЯ
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: saveDay,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text(
                'Сохранить день',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: const Color(0xFF171717),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
