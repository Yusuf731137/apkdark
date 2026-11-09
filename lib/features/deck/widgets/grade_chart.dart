import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class GradeChart extends StatelessWidget {
  /// Keys: NEW, F, E, D, C, B, A
  final Map<String, int> grades;
  const GradeChart({super.key, required this.grades});

  static const _order = ['NEW', 'F', 'E', 'D', 'C', 'B', 'A'];
  static const _colors = [
    AppColors.newCard,
    AppColors.gradeF,
    AppColors.gradeE,
    AppColors.gradeD,
    AppColors.gradeC,
    AppColors.gradeB,
    AppColors.gradeA,
  ];

  @override
  Widget build(BuildContext context) {
    final values = _order.map((k) => grades[k] ?? 0).toList();
    final maxV = values.fold<int>(0, (a, b) => a > b ? a : b);
    return SizedBox(
      height: 160,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(_order.length, (i) {
            final v = values[i];
            final h = maxV == 0 ? 4.0 : (v / maxV) * 100;
            return Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('$v', style: const TextStyle(color: AppColors.text, fontSize: 11)),
                  const SizedBox(height: 4),
                  Container(
                    width: 24,
                    height: h < 4 ? 4 : h,
                    decoration: BoxDecoration(
                      color: _colors[i],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(_order[i], style: const TextStyle(color: AppColors.muted, fontSize: 10)),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}