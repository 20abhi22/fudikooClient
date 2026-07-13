import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:fudikoclient/utils/constants.dart';

class DonutChartStatic extends StatelessWidget {
  final double percentage;

  const DonutChartStatic({super.key, required this.percentage});

  @override
  Widget build(BuildContext context) {
    final safePercentage = percentage.clamp(0.0, 1.0).toDouble();

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest.shortestSide;
        final centerSpaceRadius = size * 0.33;
        final sectionRadius = size * 0.13;
        final textSize = size * 0.15;

        return Stack(
          alignment: Alignment.center,
          children: [
            PieChart(
              PieChartData(
                sectionsSpace: 0,
                centerSpaceRadius: centerSpaceRadius,
                startDegreeOffset: -90,
                sections: [
                  PieChartSectionData(
                    value: safePercentage,
                    color: Colors.deepOrange,
                    radius: sectionRadius,
                    title: '',
                  ),
                  PieChartSectionData(
                    value: 1 - safePercentage,
                    color: Colors.deepOrange.shade100,
                    radius: sectionRadius,
                    title: '',
                  ),
                ],
              ),
            ),
            Text(
              '${(safePercentage * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: textSize,
                fontWeight: FontWeight.bold,
                color: appTextColor3,
              ),
            ),
          ],
        );
      },
    );
  }
}
