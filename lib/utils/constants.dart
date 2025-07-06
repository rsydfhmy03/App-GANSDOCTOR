// lib/utils/constants.dart

import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF0099FF);
  static const Color secondary = Color(0xFF2196F3);
  static const Color accent = Color(0xFF03A9F4);
  static const Color background = Color(0xFFF5F5F5);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color real = Color(0xFF4CAF50); // Warna untuk hasil "REAL"
  static const Color fake = Color(0xFFF44336); // Warna untuk hasil "FAKE"
}

class AppStrings {
  static const String appName = 'GANS DOCTOR';
  static const String welcome = 'Welcome to GANS Doctor!';
  static const String description =
      'Scan or upload your photos to detect\nwhether the face is real or AI-generated.';
  static const String scan = 'Scan Face';
  static const String gallery = 'Gallery';
  static const String camera = 'Camera';
  static const String result = 'Detection Result';
  static const String real = 'REAL';
  static const String fake = 'AI-GENERATED';
  static const String realDescription =
      'This photo is detected as a real human face.';
  static const String fakeDescription =
      'This photo is detected as an AI-generated face.';
  static const String confidence = 'Confidence Level';
  static const String tryAgain = 'Try Again';
  static const String processing = 'Processing...';
  static const String cameraScreen = 'Camera Screen';
}

class AppAssets {
  static const String logo = 'assets/images/logo.svg';
  static const String faceVector = 'assets/images/face_vector.svg';
  static const String realIcon = 'assets/images/real_icon.svg';
  static const String fakeIcon = 'assets/images/fake_icon.svg';
  static const String loadingAnimation = 'assets/animations/loading.json';
}
