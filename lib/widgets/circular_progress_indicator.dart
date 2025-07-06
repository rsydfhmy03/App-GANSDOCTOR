// lib/widgets/circular_progress_indicator.dart

import 'package:flutter/material.dart';
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

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: probability),
      duration: const Duration(milliseconds: 1500),
      builder: (context, value, _) {
        return Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFE0E5EC),
            boxShadow: [
              const BoxShadow(
                color: Colors.white,
                offset: Offset(-6, -6),
                blurRadius: 10,
              ),
              BoxShadow(
                color: Colors.grey.shade500,
                offset: const Offset(6, 6),
                blurRadius: 10,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Inner circle (pressed in effect)
              Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFE0E5EC),
                  boxShadow: [
                    const BoxShadow(
                      color: Colors.white,
                      offset: Offset(4, 4),
                      blurRadius: 5,
                      spreadRadius: -2,
                     
                    ),
                    BoxShadow(
                      color: Colors.grey.shade400,
                      offset: const Offset(-4, -4),
                      blurRadius: 5,
                      spreadRadius: -2,
                    
                    ),
                  ],
                ),
              ),

              // Progress ring
              SizedBox(
                width: 180,
                height: 180,
                child: CircularProgressIndicator(
                  value: value,
                  strokeWidth: 15,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  backgroundColor: color.withOpacity(0.15),
                ),
              ),

              // Text info in center
              Column(
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
            ],
          ),
        );
      },
    );
  }
}
