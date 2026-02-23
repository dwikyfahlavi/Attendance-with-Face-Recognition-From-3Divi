import 'package:dio/dio.dart';

class RemoteAuthDataSource {
  RemoteAuthDataSource({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  Future<Map<String, dynamic>> login({
    required String baseUrl,
    required String username,
    required String password,
  }) async {
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

    throw Exception('Invalid login response format');
  }
}
