import 'package:flutter/material.dart';
import '../../core/colors.dart';

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.bottomText,
    required this.iconData,
    required this.mainColor,
  });

  final String title;
  final String value; // ← было double
  final String bottomText;
  final IconData iconData;
  final Color mainColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.only(bottom: 12, top: 12, right: 12, left: 12),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Верхний ряд: заголовок + иконка
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: colors.text, fontSize: 15, fontWeight: FontWeight.w500),
                ),
              ),
              Icon(iconData, size: 20, color: mainColor),
            ],
          ),
          // Значение
          Text(
            value,
            style: TextStyle(
              color: mainColor,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          // Нижняя подпись
          Text(
            bottomText,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11),
          ),
        ],
      ),
    );
  }
}