import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:fudikoclient/utils/constants.dart';

class DonutChartStatic extends StatelessWidget {
  final double percentage;

  const DonutChartStatic({super.key, required this.percentage});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        PieChart(
          PieChartData(
            sectionsSpace: 0,
            centerSpaceRadius: 100,
            startDegreeOffset: -90,
            sections: [
              PieChartSectionData(
                value: percentage,
                color: Colors.deepOrange,
                radius: 40,
                title: '',
              ),
              PieChartSectionData(
                value: 1 - percentage,
                color: Colors.deepOrange.shade100,
                radius: 40,
                title: '',
              ),
            ],
          ),
        ),
        Text(
          '${(percentage * 100).toStringAsFixed(1)}%',
          style:  TextStyle(
            fontSize: 45,
            fontWeight: FontWeight.bold,
            color: appTextColor3,
          ),
        ),
      ],
    );
  }
}
