// lib/services/detection_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:gansdoctor/models/detection_result.dart';
import 'package:gansdoctor/config/api_config.dart';

class DetectionService {
  final Dio _dio = Dio();

  Future<DetectionResult> detectFace(File imageFile) async {
    try {
      String fileName = imageFile.path.split('/').last;
      FormData formData = FormData.fromMap({
        "image": await MultipartFile.fromFile(
          imageFile.path,
          filename: fileName,
        ),
      });

      final response = await _dio.post(
        '${ApiConfig.baseUrl}/detect',
        data: formData,
        options: Options(
          headers: {
            "Content-Type": "multipart/form-data",
          },
        ),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return DetectionResult.fromJson(response.data);
      } else {
        throw Exception('Failed to detect face: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error detecting face: $e');
    }
  }
}