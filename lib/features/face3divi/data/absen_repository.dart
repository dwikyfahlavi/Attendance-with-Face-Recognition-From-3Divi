import 'package:dio/dio.dart';
import 'package:hive/hive.dart';

import '../../../models/absen_model.dart';
import '../../../models/settings_model.dart';
import 'absen_local_data_source.dart';

class AbsenRepository {
  AbsenRepository(this._dataSource, {Dio? dio}) : _dio = dio ?? Dio();

  final AbsenLocalDataSource _dataSource;
  final Dio _dio;

  Stream<List<AbsenModel>> watchAbsen() => _dataSource.watchAbsen();

  // Aliases for consistency with naming conventions
  Stream<List<AbsenModel>> watchAttendance() => watchAbsen();

  Future<void> addAbsen(AbsenModel absen) => _dataSource.addAbsen(absen);

  // Alias for consistency with other naming
  Future<void> addAttendance(AbsenModel attendance) => addAbsen(attendance);

  Future<void> deleteAt(int index) => _dataSource.deleteAt(index);

  /// Get last attendance record for a user by employee ID
  Future<AbsenModel?> getLastAttendanceForUser(String employeeId) async {
    final allAbsen = await _dataSource.getAllAbsen();
    final userAbsen = allAbsen
        .where((absen) => absen.employeeId == employeeId)
        .toList();
    if (userAbsen.isEmpty) return null;
    userAbsen.sort((a, b) => b.jamAbsen.compareTo(a.jamAbsen));
    return userAbsen.first;
  }

  /// Get attendance records within a date range
  Future<List<AbsenModel>> getAttendanceByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final allAbsen = await _dataSource.getAllAbsen();

    // Normalize dates to midnight for day-level comparison
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

    final filtered = allAbsen
        .where(
          (absen) =>
              absen.jamAbsen.isAfter(start) &&
              absen.jamAbsen.isBefore(end.add(const Duration(seconds: 1))),
        )
        .toList();

    return filtered;
  }

  /// Get all attendance records
  Future<List<AbsenModel>> getAllAbsen() => _dataSource.getAllAbsen();

  // Alias for consistency with naming conventions
  Future<List<AbsenModel>> getAllAttendance() => getAllAbsen();

  /// Upload today's attendance data to the server
  Future<String> uploadTodaysAttendance() async {
    try {
      // Get settings
      final settingsBox = Hive.box<SettingsModel>('settings');
      final settings = settingsBox.get('settings');
      if (settings == null) {
        throw Exception('Settings not found');
      }
      final employeeCode = settings.employeeCode;
      if (employeeCode == null || employeeCode.isEmpty) {
        throw Exception('Employee code is empty');
      }
      final baseUrl = settings.apiBaseUrl;
      final url = '$baseUrl/FaceData/upload_attendance';

      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final todaysAbsen = await getAttendanceByDateRange(startOfDay, endOfDay);

      // Group by employeeId
      final grouped = <String, List<AbsenModel>>{};
      for (final absen in todaysAbsen) {
        grouped.putIfAbsent(absen.employeeId, () => []).add(absen);
      }

      final attendance = <Map<String, dynamic>>[];
      for (final entry in grouped.entries) {
        final employeeId = entry.key;
        final records = entry.value;
        records.sort((a, b) => a.jamAbsen.compareTo(b.jamAbsen));
        final clockIn = _formatDateTime(records.first.jamAbsen);
        final clockOut = _formatDateTime(records.last.jamAbsen);
        attendance.add({
          'employee_id': employeeId,
          'attendance_code': 'K',
          'clock_in': clockIn,
          'clock_out': clockOut,
        });
      }

      final body = {'employee_code': employeeCode, 'data': attendance};

      final response = await _dio.post<dynamic>(
        url,
        data: body,
        options: Options(
          headers: {'Content-Type': 'application/json'},
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      // Parse response data
      final responseData = response.data;
      if (responseData is Map<String, dynamic>) {
        final status = responseData['status'];
        final message = responseData['message'] ?? 'Unknown response';

        // Check for successful response
        if (response.statusCode != 200 && response.statusCode != 201) {
          throw Exception(message);
        }
        if (status == true) {
          // Success - return the message
          return message;
        } else {
          // API indicated failure
          throw Exception(message);
        }
      } else {
        throw Exception('Invalid response format from server.');
      }
    } on DioException catch (e) {
      throw Exception(_mapDioErrorToMessage(e));
    } catch (_) {
      throw Exception(
        'Unable to upload attendance right now. Please try again.',
      );
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return dateTime.toString().split('.').first;
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
        if (statusCode == 401 || statusCode == 403 || statusCode == 400) {
          return error.response?.data is Map<String, dynamic> &&
                  error.response?.data['message'] != null
              ? error.response!.data['message'].toString()
              : 'Unauthorized. Please check your credentials.';
        }
        if (statusCode >= 500) {
          return 'Server is busy. Please try again later.';
        }
        return 'Upload request failed. Please verify your input and try again.';
      case DioExceptionType.cancel:
        return 'Request was cancelled. Please try again.';
      case DioExceptionType.badCertificate:
        return 'Secure connection failed. Please contact administrator.';
      case DioExceptionType.unknown:
        return 'Network error occurred. Please try again.';
    }
  }
}
