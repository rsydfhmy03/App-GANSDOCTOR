// lib/widgets/circular_progress_indicator.dart

import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:gansdoctor/utils/constants.dart';
import 'package:gansdoctor/utils/helpers.dart';

class ResultCircularProgress extends StatelessWidget {
  final String label;
  final double probability;

  const ResultCircularProgress({
    Key? key,
    required this.label,
    required this.probability,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = Helpers.getColorForLabel(label);
    final percentage = Helpers.getFormattedPercentage(probability);
    
    return CircularPercentIndicator(
      radius: 80.0,
      lineWidth: 15.0,
      animation: true,
      animationDuration: 1500,
      percent: probability,
      center: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            percentage,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
      circularStrokeCap: CircularStrokeCap.round,
      progressColor: color,
      backgroundColor: color.withOpacity(0.2),
    );
  }
}