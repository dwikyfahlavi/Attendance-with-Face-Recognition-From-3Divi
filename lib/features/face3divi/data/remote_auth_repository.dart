import 'dart:convert';

import '../../../models/user_model.dart';
import 'remote_auth_data_source.dart';
import 'settings_repository.dart';
import 'user_repository.dart';

class RemoteAuthRepository {
  RemoteAuthRepository({
    required SettingsRepository settingsRepository,
    required UserRepository userRepository,
    required RemoteAuthDataSource remoteAuthDataSource,
  }) : _settingsRepository = settingsRepository,
       _userRepository = userRepository,
       _remoteAuthDataSource = remoteAuthDataSource;

  final SettingsRepository _settingsRepository;
  final UserRepository _userRepository;
  final RemoteAuthDataSource _remoteAuthDataSource;

  Future<RegisteredUser> loginAndSyncUser({
    required String username,
    required String password,
  }) async {
    final settings = await _settingsRepository.getSettings();
    final response = await _remoteAuthDataSource.login(
      baseUrl: settings.apiBaseUrl,
      username: username,
      password: password,
    );

    final users = _mapLoginResponseToUsers(response);
    if (users.isEmpty) {
      throw Exception('Invalid login response: M_Employee_Schema is empty');
    }

    for (final user in users) {
      await _userRepository.addOrUpdateUser(user);
    }

    return users.first;
  }

  List<RegisteredUser> _mapLoginResponseToUsers(
    Map<String, dynamic> responseData,
  ) {
    final global =
        (responseData['global'] as Map<String, dynamic>?) ?? responseData;
    final employeeSchemaRaw = global['M_Employee_Schema'];

    final employeeItems = <Map<String, dynamic>>[];
    if (employeeSchemaRaw is List) {
      for (final item in employeeSchemaRaw) {
        if (item is Map<String, dynamic>) {
          employeeItems.add(item);
        }
      }
    } else if (employeeSchemaRaw is Map<String, dynamic>) {
      employeeItems.add(employeeSchemaRaw);
    }

    final results = <RegisteredUser>[];
    for (final employeeData in employeeItems) {
      final nik = (employeeData['employee_code'] ?? '').toString().trim();
      final name = (employeeData['employee_name'] ?? '').toString().trim();
      if (nik.isEmpty || name.isEmpty) {
        continue;
      }

      final existing = _userRepository.getUserByNik(nik);
      final mappedUser = RegisteredUser(
        nik: nik,
        nama: name,
        isAdmin: existing?.isAdmin ?? false,
        department: _readStringIfPresent(employeeData, 'employee_profile'),
        hasTemplate: existing?.hasTemplate ?? false,
        imageBytes: existing?.imageBytes,
        employeeId: _readIntIfPresent(employeeData, 'employee_id'),
        employeeRole: _readStringIfPresent(employeeData, 'employee_job_code'),
        companyCode: _readStringIfPresent(employeeData, 'company_code'),
        estateCode: _readStringIfPresent(
          employeeData,
          'employee_gang_allotment_code',
        ),
        plantCode: _readStringIfPresent(employeeData, 'employee_vendor'),
        lastAttendanceTime: existing?.lastAttendanceTime,
        rawUserJson: jsonEncode(employeeData),
      );
      results.add(mappedUser);
    }

    return results;
  }

  int? _toNullableInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  String? _toNullableString(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  int? _readIntIfPresent(Map<String, dynamic> data, String key) {
    if (!data.containsKey(key)) {
      return null;
    }
    return _toNullableInt(data[key]);
  }

  String? _readStringIfPresent(Map<String, dynamic> data, String key) {
    if (!data.containsKey(key)) {
      return null;
    }
    return _toNullableString(data[key]);
  }
}
