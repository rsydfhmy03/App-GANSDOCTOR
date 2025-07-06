import 'package:flutter/material.dart';
import 'package:gansdoctor/models/detection_result.dart';
import 'package:gansdoctor/utils/constants.dart';
import 'package:gansdoctor/utils/helpers.dart';
import 'package:gansdoctor/widgets/circular_progress_indicator.dart';
import 'package:gansdoctor/widgets/custom_button.dart';

class ResultScreen extends StatelessWidget {
  final DetectionResult result;

  const ResultScreen({
    Key? key,
    required this.result,
  }) : super(key: key);

  BoxDecoration _neumorphicBox({bool isPressed = false}) {
    return BoxDecoration(
      color: const Color(0xFFE0E5EC),
      borderRadius: BorderRadius.circular(20),
      boxShadow: isPressed
          ? [
              const BoxShadow(
                color: Colors.white,
                offset: Offset(-5, -5),
                blurRadius: 10,
              ),
              BoxShadow(
                color: Colors.grey.shade400,
                offset: const Offset(5, 5),
                blurRadius: 10,
              ),
            ]
          : [
              const BoxShadow(
                color: Colors.white,
                offset: Offset(-5, -5),
                blurRadius: 15,
              ),
              BoxShadow(
                color: Colors.grey.shade500,
                offset: const Offset(5, 5),
                blurRadius: 15,
              ),
            ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isReal = result.label == 'REAL';
    final color = Helpers.getColorForLabel(result.label);
    final description = Helpers.getDescriptionForLabel(result.label);

    return Scaffold(
      backgroundColor: const Color(0xFFE0E5EC),
      appBar: AppBar(title: const Text(AppStrings.result), centerTitle: true, elevation: 0,),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Image Container with neumorphism
              Container(
                width: double.infinity,
                height: 300,
                decoration: _neumorphicBox(),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(
                    result.imageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(child: CircularProgressIndicator());
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(Icons.broken_image, size: 80),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Label Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: _neumorphicBox(isPressed: true).copyWith(
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  isReal ? AppStrings.real : AppStrings.fake,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Description
              Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 20),

              // Confidence Indicator
              Column(
                  children: [
                    const Text(
                      AppStrings.confidence,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ResultCircularProgress(
                      label: result.label,
                      probability: result.confidence,
                    ),
                  ],
                ),
              

              const SizedBox(height: 40),

              // Probabilities
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: _neumorphicBox(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Detail Probabilitas:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 15),
                    ...result.probabilities.entries.map((entry) {
                      final isRealLabel = entry.key == 'REAL';
                      final entryColor = isRealLabel ? AppColors.real : AppColors.fake;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: _neumorphicBox(isPressed: true).copyWith(
                                borderRadius: BorderRadius.circular(10),
                                color: entryColor.withOpacity(0.1),
                              ),
                              child: Center(
                                child: Icon(
                                  isRealLabel ? Icons.check_circle : Icons.cancel,
                                  color: entryColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 15),
                            Text(
                              isRealLabel ? 'REAL' : 'FAKE',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              Helpers.getFormattedPercentage(entry.value),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: entryColor,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Try Again Button
              CustomButton(
                text: AppStrings.tryAgain,
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
