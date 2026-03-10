import 'package:dio/dio.dart';
import 'package:hive/hive.dart';

import '../models/absen_model.dart';
import '../models/settings_model.dart';
import '../data_source/absen_local_data_source.dart';
import 'user_repository.dart';

class AbsenRepository {
  AbsenRepository(this._dataSource, this._userRepository, {Dio? dio})
    : _dio = dio ?? Dio();

  final AbsenLocalDataSource _dataSource;
  final Dio _dio;
  final UserRepository _userRepository;

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

  /// Get last attendance record for a user by employee ID and type
  Future<AbsenModel?> getLastAttendanceForUserAndType(
    String employeeId,
    String type,
  ) async {
    final allAbsen = await _dataSource.getAllAbsen();
    final userAbsen = allAbsen
        .where((absen) => absen.employeeId == employeeId && absen.type == type)
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

  /// Get today's attendance records
  Future<List<AbsenModel>> getTodaysAbsen() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return getAttendanceByDateRange(startOfDay, endOfDay);
  }

  /// Upload today's attendance data to the server
  Future<String> uploadTodaysAttendance() async {
    try {
      // Get settings
      final settingsBox = Hive.box<SettingsModel>('settings');
      final settings = settingsBox.get('settings');
      if (settings == null) {
        throw Exception('Settings not found');
      }
      final userId = settings.userId;
      if (userId == null || userId.isEmpty) {
        throw Exception('User ID is empty');
      }
      final attendanceCode = settings.attendanceCode;
      if (attendanceCode == null || attendanceCode.isEmpty) {
        throw Exception('Attendance code is empty');
      }
      final unattendanceCode = settings.unattendanceCode;
      if (unattendanceCode == null || unattendanceCode.isEmpty) {
        throw Exception('Unattendance code is empty');
      }
      final baseUrl = settings.apiBaseUrl;
      final url = '$baseUrl/FaceData/upload_attendance';

      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      final todaysAbsen = await getAttendanceByDateRange(startOfDay, endOfDay);

      // Group attendance by employeeId for quick lookup
      final attendanceMap = <String, List<AbsenModel>>{};
      for (final absen in todaysAbsen) {
        attendanceMap.putIfAbsent(absen.employeeId, () => []).add(absen);
      }

      // Get all registered users
      final allUsers = _userRepository.getAllUsers();

      final attendance = <Map<String, dynamic>>[];
      for (final user in allUsers) {
        final employeeId = user.employeeId;
        final records = attendanceMap[employeeId] ?? [];

        if (records.isNotEmpty) {
          // Employee has attendance - use attendanceCode
          records.sort((a, b) => a.jamAbsen.compareTo(b.jamAbsen));
          final checkInRecords = records
              .where((r) => r.type == 'CheckIn')
              .toList();
          final checkOutRecords = records
              .where((r) => r.type == 'CheckOut')
              .toList();
          final checkInRecord = checkInRecords.isNotEmpty
              ? checkInRecords.first
              : null;
          final checkOutRecord = checkOutRecords.isNotEmpty
              ? checkOutRecords.last
              : null;

          // if (checkInRecord != null) {
          attendance.add({
            'employee_id': employeeId,
            'attendance_code': attendanceCode,
            'clock_in': checkInRecord != null
                ? _formatDateTime(checkInRecord.jamAbsen)
                : null,
            'clock_out': checkOutRecord != null
                ? _formatDateTime(checkOutRecord.jamAbsen)
                : null,
          });
          // }
        } else {
          // Employee has no attendance - use unattendanceCode
          attendance.add({
            'employee_id': employeeId,
            'attendance_code': unattendanceCode,
            'clock_in': null,
            'clock_out': null,
          });
        }
      }

      // Determine created_date and updated_date
      final createdDates = todaysAbsen.isNotEmpty
          ? todaysAbsen.first.createdDate
          : null;
      final createdDate = createdDates ?? DateTime.now();
      final updatedDate = createdDates != null ? DateTime.now() : null;

      final body = {
        'user_id': userId,
        'created_date': _formatDateTime(createdDate),
        'updated_date': updatedDate != null
            ? _formatDateTime(updatedDate)
            : null,
        'data': attendance,
      };

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
          // Success - mark local records as uploaded
          for (final absen in todaysAbsen) {
            absen.isUploaded = true;
            await absen.save();
          }
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

  /// Fetch attendance history from the server
  Future<List<AbsenModel>> fetchAttendanceHistory() async {
    try {
      // Get settings
      final settingsBox = Hive.box<SettingsModel>('settings');
      final settings = settingsBox.get('settings');
      if (settings == null) {
        throw Exception('Settings not found');
      }
      final userId = settings.userId;
      if (userId == null || userId.isEmpty) {
        throw Exception('User ID is empty');
      }
      final baseUrl = settings.apiBaseUrl;
      final url = '$baseUrl/FaceData/get_attendance_last_5_days';

      final response = await _dio.get<dynamic>(
        url,
        options: Options(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;
        final data = responseData['data'] as List;
        final list = data.map((e) => e as Map<String, dynamic>).toList();
        final absenList = list
            .map((json) => AbsenModel.fromApi(json))
            .expand((e) => e)
            .toList();
        return absenList;
      } else {
        throw Exception('Failed to fetch attendance history.');
      }
    } on DioException catch (e) {
      throw Exception(_mapDioErrorToMessage(e));
    } catch (e) {
      throw Exception('Unable to fetch attendance history. Please try again.');
    }
  }

  /// Clear all attendance data from local storage
  Future<void> clearAllAbsen() async {
    final box = await Hive.openBox<AbsenModel>('absen');
    await box.clear();
  }

  /// Clean up old attendance data (keep only today's)
  Future<void> cleanupOldData() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final allAbsen = await getAllAbsen();
    for (final absen in allAbsen) {
      if (absen.jamAbsen.isBefore(startOfDay) || absen.isUploaded) {
        await absen.delete();
      }
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
