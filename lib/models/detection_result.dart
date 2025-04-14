// lib/models/detection_result.dart

class DetectionResult {
  final String label;
  final double confidence;
  final Map<String, double> probabilities;
  final String message;
  final int statusCode;

  DetectionResult({
    required this.label,
    required this.confidence,
    required this.probabilities,
    required this.message,
    required this.statusCode,
  });

  factory DetectionResult.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> data = json['data'];
    Map<String, double> probs = {};
    
    (data['probabilities'] as Map<String, dynamic>).forEach((key, value) {
      probs[key] = value is double ? value : (value as num).toDouble();
    });

    return DetectionResult(
      label: data['label'],
      confidence: data['confidence'] is double ? data['confidence'] : (data['confidence'] as num).toDouble(),
      probabilities: probs,
      message: json['message'],
      statusCode: json['statusCode'],
    );
  }
}