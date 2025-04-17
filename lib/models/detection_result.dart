// lib/models/detection_result.dart

class DetectionResult {
  final int statusCode;
  final String message;
  final String label;
  final double confidence;
  final Map<String, double> probabilities;

  DetectionResult({
    required this.statusCode,
    required this.message,
    required this.label,
    required this.confidence,
    required this.probabilities,
  });

  factory DetectionResult.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> data = json['data'];
    Map<String, double> probs = {};
    
    (data['probabilities'] as Map<String, dynamic>).forEach((key, value) {
      probs[key] = value is double ? value : (value as num).toDouble();
    });

    return DetectionResult(
      statusCode: json['statusCode'],
      message: json['message'],
      label: data['label'],
      confidence: data['confidence'] is double ? data['confidence'] : (data['confidence'] as num).toDouble(),
      probabilities: probs,
    );
  }
}