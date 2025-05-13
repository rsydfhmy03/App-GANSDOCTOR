import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:gansdoctor/models/detection_result.dart';
import 'package:gansdoctor/config/api_config.dart';

class DetectionService {
  final Dio _dio = Dio()
    ..interceptors.add(LogInterceptor(
      request: true,
      requestHeader: true,
      requestBody: true,
      responseHeader: false,
      responseBody: true,
      error: true,
      logPrint: (obj) => print('[DIO] $obj'),
    ));

  /// Deteksi wajah dengan metode CNN standar (tanpa LBP)
  Future<DetectionResult> detectFace(File imageFile) async {
    return _uploadImageAndDetect(
      imageFile,
      '${ApiConfig.baseUrl}/api/v1/detect',
    );
  }

  /// Deteksi wajah dengan metode LBP + CNN
  Future<DetectionResult> detectFaceLBP(File imageFile) async {
    return _uploadImageAndDetect(
      imageFile,
      '${ApiConfig.baseUrl}/api/v1/detectLBP',
    );
  }

  /// Method private yang digunakan untuk mengirim request ke endpoint
  Future<DetectionResult> _uploadImageAndDetect(File imageFile, String url) async {
    try {
      String fileName = imageFile.path.split('/').last;
      print('[DETECT] Preparing image: $fileName');
      print('[DETECT] Using endpoint: $url');

      FormData formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(
          imageFile.path,
          filename: fileName,
        ),
      });

      final response = await _dio.post(
        url,
        data: formData,
        options: Options(
          headers: {
            "Content-Type": "multipart/form-data",
          },
        ),
      );

      print('[DETECT] Response status: ${response.statusCode}');
      print('[DETECT] Response data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return DetectionResult.fromJson(response.data);
      } else {
        throw Exception('Failed to detect face: ${response.statusCode}');
      }
    } catch (e, stacktrace) {
      print('[DETECTION ERROR] $e');
      print('[STACKTRACE] $stacktrace');
      throw Exception('Error detecting face: $e');
    }
  }
}
