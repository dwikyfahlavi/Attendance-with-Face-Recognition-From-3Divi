import 'package:dio/dio.dart';

class RemoteAuthException implements Exception {
  final String message;
  const RemoteAuthException(this.message);

  @override
  String toString() => message;
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
          return 'Invalid username or password.';
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
