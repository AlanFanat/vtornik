import 'package:flutter/material.dart';

const Color mainColor = Color(0xFF0C0C0D);

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
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              const Icon(Icons.star, size: 40, color: Colors.amber),
              const SizedBox(width: 20),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'My Days',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Practice makes perfect',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              onPressed: () {
                // TODO: Открыть настройки
              },
              icon: const Icon(Icons.settings_outlined, size: 30),
            ),
          ),
        ],
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const MonthCalendar(),

              const SizedBox(height: 16),

              const DayEditor(),
            ],
          ),
        ),
      ),
    );
  }
}

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
            'October 2026',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ),

        const SizedBox(height: 16),

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

        const SizedBox(height: 8),

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
                color: const Color(0xFF242428),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                '$day',
                style: const TextStyle(color: Colors.white, fontSize: 14),
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
        color: const Color(0xFF18181C),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF29292F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Оценка дня',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 2),

          const Text(
            'Как прошёл твой день?',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),

          const SizedBox(height: 10),

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
                    color: isSelected
                        ? colorForRating(rating)
                        : const Color(0xFF29292F),
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
                      color: isSelected ? Colors.black : Colors.white,
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
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),

          const SizedBox(height: 2),

          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: tags.map((tag) {
              final isSelected = selectedTags.contains(tag);

              return FilterChip(
                label: Text(tag, style: const TextStyle(fontSize: 12)),
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
                selectedColor: const Color(0xFFE5B84B),
                checkmarkColor: Colors.black,
                backgroundColor: const Color(0xFF29292F),
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

          const SizedBox(height: 2),

          // ЗАМЕТКА
          const Text(
            'Заметка',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),

          const SizedBox(height: 6),

          TextField(
            controller: noteController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Что хорошего произошло сегодня?',
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
              filled: true,
              fillColor: const Color(0xFF222227),
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
                backgroundColor: const Color(0xFFE5B84B),
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
