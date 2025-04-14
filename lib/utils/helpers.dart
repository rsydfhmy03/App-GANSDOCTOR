// lib/utils/helpers.dart

import 'package:flutter/material.dart';
import 'package:gansdoctor/utils/constants.dart';
// import 'package:gans_doctor/utils/constants.dart';


class Helpers {
  static Color getColorForLabel(String label) {
    return label == 'REAL' ? AppColors.real : AppColors.fake;
  }

  static String getDescriptionForLabel(String label) {
    return label == 'REAL' ? AppStrings.realDescription : AppStrings.fakeDescription;
  }

  static String getFormattedPercentage(double value) {
    return '${(value * 100).toStringAsFixed(1)}%';
  }

  static void showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static void showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(AppStrings.processing),
            ],
          ),
        ),
      ),
    );
  }
}