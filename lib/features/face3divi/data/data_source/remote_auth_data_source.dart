import 'package:dio/dio.dart';

class RemoteAuthException implements Exception {
  final String message;
  const RemoteAuthException(this.message);

  @override
  String toString() => message;
}

class UploadTemplateApiError {
  final int? index;
  final String? employeeId;
  final String message;

  const UploadTemplateApiError({
    required this.index,
    required this.employeeId,
    required this.message,
  });
}

class UploadFaceTemplatesResult {
  final bool status;
  final int totalPosted;
  final int totalSuccess;
  final int totalError;
  final List<UploadTemplateApiError> errorData;

  const UploadFaceTemplatesResult({
    required this.status,
    required this.totalPosted,
    required this.totalSuccess,
    required this.totalError,
    required this.errorData,
  });
}

class RemoteAuthDataSource {
  RemoteAuthDataSource({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  Future<Map<String, dynamic>> login({
    required String baseUrl,
    required String username,
    required String password,
  }) async {
    try {
      final url = '$baseUrl/auth/login';
      final formData = FormData.fromMap({
        'user_login': username,
        'password': password,
        'is_empty': 1,
      });

      final response = await _dio.post<dynamic>(
        url,
        data: formData,
        options: Options(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        return data;
      }

      throw const RemoteAuthException('Invalid response from server.');
    } on DioException catch (e) {
      throw RemoteAuthException(_mapDioErrorToMessage(e));
    } on RemoteAuthException {
      rethrow;
    } catch (_) {
      throw const RemoteAuthException(
        'Unable to login right now. Please try again.',
      );
    }
  }

  Future<UploadFaceTemplatesResult> uploadFaceTemplates({
    required String baseUrl,
    required String userId,
    required List<Map<String, String>> templates,
  }) async {
    try {
      final url = '$baseUrl/FaceData/face_data';
      final body = {'user_id': userId, 'data': templates};

      final response = await _dio.post<dynamic>(
        url,
        data: body,
        options: Options(
          headers: {'Content-Type': 'application/json'},
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      // // Check for successful response
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw RemoteAuthException('Failed to upload face templates.');
      }

      final responseData = response.data;
      if (responseData is! Map<String, dynamic>) {
        throw const RemoteAuthException('Invalid upload response from server.');
      }

      final rawErrors = responseData['error_data'];
      final parsedErrors = <UploadTemplateApiError>[];
      if (rawErrors is List) {
        for (final item in rawErrors) {
          if (item is Map<String, dynamic>) {
            final rawIndex = item['index'];
            parsedErrors.add(
              UploadTemplateApiError(
                index: rawIndex is int
                    ? rawIndex
                    : int.tryParse('${item['index']}'),
                employeeId: item['employee_id']?.toString(),
                message: item['message']?.toString() ?? 'Unknown upload error',
              ),
            );
          }
        }
      }

      return UploadFaceTemplatesResult(
        status: responseData['status'] == true,
        totalPosted: _toInt(responseData['total_posted']),
        totalSuccess: _toInt(responseData['total_success']),
        totalError: _toInt(responseData['total_error']),
        errorData: parsedErrors,
      );
    } on DioException catch (e) {
      throw RemoteAuthException(_mapDioErrorToMessage(e));
    } catch (_) {
      throw const RemoteAuthException(
        'Unable to upload face templates right now. Please try again.',
      );
    }
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '0') ?? 0;
  }

  String _mapDioErrorToMessage(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timeout. Please check your network and try again.';
      case DioExceptionType.connectionError:
        return 'Unable to connect to server. Check your IP settings and network.';
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode ?? 0;
        if (statusCode == 401 || statusCode == 403) {
          return error.response?.data is Map<String, dynamic> &&
                  error.response?.data['message'] != null
              ? error.response!.data['message'].toString()
              : 'Unauthorized. Please check your credentials.';
        }
        if (statusCode >= 500) {
          return 'Server is busy. Please try again later.';
        }
        return 'Login request failed. Please verify your input and try again.';
      case DioExceptionType.cancel:
        return 'Request was cancelled. Please try again.';
      case DioExceptionType.badCertificate:
        return 'Secure connection failed. Please contact administrator.';
      case DioExceptionType.unknown:
        return 'Network error occurred. Please try again.';
    }
  }
}
