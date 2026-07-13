import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class DonutChart extends StatelessWidget {
  final double percentage;

  const DonutChart({super.key, required this.percentage});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final shortestSide = constraints.biggest.shortestSide;
        final chartSize = shortestSide.isFinite ? shortestSide : 100.0;
        final sectionRadius = (chartSize * 0.2).clamp(14.0, 24.0).toDouble();
        final centerRadius = (chartSize * 0.3).clamp(22.0, 36.0).toDouble();
        final textSize = (chartSize * 0.12).clamp(10.0, 14.0).toDouble();
        final clampedPercentage = percentage.clamp(0.0, 1.0).toDouble();

        return Stack(
          alignment: Alignment.center,
          children: [
            PieChart(
              PieChartData(
                sectionsSpace: 0,
                centerSpaceRadius: centerRadius,
                startDegreeOffset: -90,
                sections: [
                  PieChartSectionData(
                    value: clampedPercentage,
                    color: Colors.deepOrange,
                    radius: sectionRadius,
                    title: '',
                  ),
                  PieChartSectionData(
                    value: 1 - clampedPercentage,
                    color: Colors.deepOrange.shade100,
                    radius: sectionRadius,
                    title: '',
                  ),
                ],
              ),
            ),
            Text(
              '${(clampedPercentage * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: textSize,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        );
      },
    );
  }
}
