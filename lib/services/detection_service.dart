import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:gansdoctor/models/detection_result.dart';
import 'package:gansdoctor/config/api_config.dart';

enum DetectionErrorType {
  noFaceDetected,
  connectionError,
  serverError,
  invalidResponse,
  unknown
}

class DetectionException implements Exception {
  final DetectionErrorType type;
  final String message;
  final int? statusCode;

  DetectionException({
    required this.type,
    required this.message,
    this.statusCode,
  });

  @override
  String toString() => message;
}

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
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      print('[DETECT] Response status: ${response.statusCode}');
      print('[DETECT] Response data: ${response.data}');

      // Handle success responses
      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          return DetectionResult.fromJson(response.data);
        } catch (e) {
          throw DetectionException(
            type: DetectionErrorType.invalidResponse,
            message: 'Response format tidak valid dari server',
          );
        }
      }

      // Handle specific error responses
      if (response.statusCode == 404) {
        final responseData = response.data;
        if (responseData is Map<String, dynamic> && 
            responseData['message']?.toString().toLowerCase().contains('face not detected') == true) {
          throw DetectionException(
            type: DetectionErrorType.noFaceDetected,
            message: 'Wajah tidak terdeteksi dalam gambar',
            statusCode: response.statusCode,
          );
        }
      }

      // Handle other HTTP errors
      if (response.statusCode != null && response.statusCode! >= 400) {
        throw DetectionException(
          type: DetectionErrorType.serverError,
          message: 'Server mengalami masalah, silakan coba lagi',
          statusCode: response.statusCode,
        );
      }

      // Fallback for unexpected status codes
      throw DetectionException(
        type: DetectionErrorType.unknown,
        message: 'Terjadi kesalahan yang tidak diketahui',
        statusCode: response.statusCode,
      );

    } on DioException catch (dioError) {
      print('[DETECTION ERROR] DioException: ${dioError.type}');
      print('[DETECTION ERROR] Message: ${dioError.message}');
      
      switch (dioError.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          throw DetectionException(
            type: DetectionErrorType.connectionError,
            message: 'Koneksi timeout, periksa jaringan internet Anda',
          );
          
        case DioExceptionType.connectionError:
          if (dioError.error is SocketException) {
            final socketError = dioError.error as SocketException;
            if (socketError.message.contains('Failed host lookup')) {
              throw DetectionException(
                type: DetectionErrorType.connectionError,
                message: 'Tidak dapat terhubung ke server, periksa koneksi internet Anda',
              );
            }
          }
          throw DetectionException(
            type: DetectionErrorType.connectionError,
            message: 'Masalah koneksi jaringan, silakan coba lagi',
          );
          
        case DioExceptionType.badResponse:
          final statusCode = dioError.response?.statusCode;
          if (statusCode == 404) {
            final responseData = dioError.response?.data;
            if (responseData is Map<String, dynamic> && 
                responseData['message']?.toString().toLowerCase().contains('face not detected') == true) {
              throw DetectionException(
                type: DetectionErrorType.noFaceDetected,
                message: 'Wajah tidak terdeteksi dalam gambar',
                statusCode: statusCode,
              );
            }
          }
          throw DetectionException(
            type: DetectionErrorType.serverError,
            message: 'Server mengalami masalah, silakan coba lagi',
            statusCode: statusCode,
          );
          
        case DioExceptionType.cancel:
          throw DetectionException(
            type: DetectionErrorType.unknown,
            message: 'Permintaan dibatalkan',
          );
          
        default:
          throw DetectionException(
            type: DetectionErrorType.unknown,
            message: 'Terjadi kesalahan yang tidak diketahui',
          );
      }
    } catch (e) {
      if (e is DetectionException) {
        rethrow;
      }
      
      print('[DETECTION ERROR] Unexpected error: $e');
      throw DetectionException(
        type: DetectionErrorType.unknown,
        message: 'Terjadi kesalahan yang tidak diketahui',
      );
    }
  }
}