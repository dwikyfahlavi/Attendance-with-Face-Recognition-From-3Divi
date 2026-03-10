import 'dart:convert';

import '../models/user_model.dart';
import '../data_source/remote_auth_data_source.dart';
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

  Future<String?> getCurrentUserId() async {
    final settings = await _settingsRepository.getSettings();
    return settings.userId;
  }

  Future<String> loginAndSyncUser({
    required String username,
    required String password,
  }) async {
    try {
      final settings = await _settingsRepository.getSettings();
      final response = await _remoteAuthDataSource.login(
        baseUrl: settings.apiBaseUrl,
        username: username,
        password: password,
      );

      if (!isFieldStaffRole(response)) {
        throw const RemoteAuthException(
          'Login failed: User does not have admin privileges.',
        );
      }

      final users = _mapLoginResponseToUsers(response);
      final currentUser = _mapCurrentUser(response);

      if (currentUser['employee_code'] != null &&
          currentUser['employee_code']!.isNotEmpty) {
        await _settingsRepository.setCurrentEmployeeAndAttendanceCode(
          currentUser['employee_code'] ?? '',
          currentUser['employee_name'] ?? '',
          currentUser['user_id'] ?? '',
          currentUser['attendance_code'] ?? '',
          currentUser['unattendance_code'] ?? '',
        );
      }
      if (users.isEmpty) {
        throw const RemoteAuthException(
          'Login succeeded, but user data was not found.',
        );
      }

      for (final user in users) {
        await _userRepository.addOrUpdateUser(user);
      }

      return currentUser['employee_name'] ?? '';
    } on RemoteAuthException {
      rethrow;
    } catch (e) {
      throw RemoteAuthException(
        'Unable to process login data. Please try again. ${e.toString()}',
      );
    }
  }

  Future<UploadFaceTemplatesResult> uploadFaceTemplates(
    List<Map<String, String>> templates,
  ) async {
    final settings = await _settingsRepository.getSettings();
    return _remoteAuthDataSource.uploadFaceTemplates(
      baseUrl: settings.apiBaseUrl,
      userId: settings.userId!,
      templates: templates,
    );
  }

  Map<String, String> _mapCurrentUser(Map<String, dynamic> responseData) {
    final global =
        (responseData['global'] as Map<String, dynamic>?) ?? responseData;
    final employeeSchemaRaw =
        (global['M_Config_Schema'] as List<dynamic>).first;

    // Assuming M_Config_Schema is a JSON string, decode it
    final Map<String, dynamic> configSchema;
    if (employeeSchemaRaw is String) {
      configSchema = jsonDecode(employeeSchemaRaw) as Map<String, dynamic>;
    } else if (employeeSchemaRaw is Map<String, dynamic>) {
      configSchema = employeeSchemaRaw;
    } else {
      throw const RemoteAuthException('Invalid M_Config_Schema format.');
    }

    // Get the first allowed attendance code
    String? firstAllowedCode = '';
    final allowedCodes =
        configSchema['allowed_attendance_codes_for_work_assignment'] as List?;
    if (allowedCodes != null && allowedCodes.isNotEmpty) {
      final firstCode = allowedCodes.first as Map<String, dynamic>;
      firstAllowedCode =
          _toNullableString(firstCode['allowed_attendance_code']) ?? '';
    }

    return {
      'employee_code': _toNullableString(configSchema['employee_code']) ?? '',
      'employee_name': _toNullableString(configSchema['employee_name']) ?? '',
      'user_id': _toNullableString(configSchema['user_id']) ?? '',
      'attendance_code': firstAllowedCode,
      'unattendance_code':
          _toNullableString(configSchema['attendance_unattendded_value']) ?? '',
    };
  }

  bool isFieldStaffRole(Map<String, dynamic> responseData) {
    final global =
        (responseData['global'] as Map<String, dynamic>?) ?? responseData;
    if (global['Roles_Schema'] == null ||
        (global['Roles_Schema'] as List).isEmpty) {
      //this role can\'t login in mobile app.
      throw const RemoteAuthException(
        'Login failed: User role can\'t login to mobile app. Please contact administrator.',
      );
    }
    final role = (global['Roles_Schema'] as List).first['user_roles'];

    return role != null && role.toLowerCase() == 'field_staff';
  }

  List<RegisteredUser> _mapLoginResponseToUsers(
    Map<String, dynamic> responseData,
  ) {
    final global =
        (responseData['global'] as Map<String, dynamic>?) ?? responseData;
    final employeeSchemaRaw = global['M_Employee_Schema'];

    // Assuming M_Employee_Schema is a JSON string, decode it
    final dynamic decodedSchema;
    if (employeeSchemaRaw is String) {
      decodedSchema = jsonDecode(employeeSchemaRaw);
    } else {
      decodedSchema = employeeSchemaRaw;
    }

    final employeeItems = <Map<String, dynamic>>[];
    if (decodedSchema is List) {
      for (final item in decodedSchema) {
        if (item is Map<String, dynamic>) {
          employeeItems.add(item);
        }
      }
    } else if (decodedSchema is Map<String, dynamic>) {
      employeeItems.add(decodedSchema);
    }

    final results = <RegisteredUser>[];
    for (final employeeData in employeeItems) {
      final apiJson = _mapEmployeeToApiJson(employeeData);
      final employeeId = (apiJson['employeeId'] ?? '').toString().trim();
      final employeeName = (apiJson['employeeName'] ?? '').toString().trim();
      if (employeeId.isEmpty || employeeName.isEmpty) {
        continue;
      }

      final existing = _userRepository.getUserByEmployeeId(employeeId);
      final mappedUser = RegisteredUser.fromApiJson(apiJson, existing);
      // print(mappedUser.toApiJson());

      results.add(mappedUser);
    }

    return results;
  }

  String? _toNullableString(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  String? _readStringIfPresent(Map<String, dynamic> data, String key) {
    if (!data.containsKey(key)) {
      return null;
    }
    return _toNullableString(data[key]);
  }

  Map<String, dynamic> _mapEmployeeToApiJson(
    Map<String, dynamic> employeeData,
  ) {
    return {
      'employeeId': _readStringIfPresent(employeeData, 'employee_id') ?? '',
      'employeeName': _readStringIfPresent(employeeData, 'employee_name') ?? '',
      'isAdmin': false,
      'department': _readStringIfPresent(employeeData, 'employee_profile'),
      'lastAttendanceTime': null,
      'employeeRole': _readStringIfPresent(employeeData, 'employee_job_code'),
      'companyCode': _readStringIfPresent(employeeData, 'company_code'),
      'estateCode': _readStringIfPresent(
        employeeData,
        'employee_gang_allotment_code',
      ),
      'employee_face_template': employeeData['employee_face_template'],
      'plantCode': _readStringIfPresent(employeeData, 'employee_vendor'),
    };
  }

  /// Generate mock face template data for testing bulk upload API
  Future<List<Map<String, String>>> generateMockFaceTemplates() async {
    // Get all registered users
    final users = _userRepository.getAllUsers();

    if (users.isEmpty) {
      throw const RemoteAuthException(
        'No registered users found. Please register at least one user first.',
      );
    }

    // Get the first user and their face template
    final firstUser = users.first;
    if (firstUser.imageBytes == null || firstUser.imageBytes!.isEmpty) {
      throw const RemoteAuthException(
        'First user does not have a face template. Please register a user with face data.',
      );
    }

    // Convert face template to base64 string
    final base64Template = base64Encode(firstUser.imageBytes!);

    // Generate 50 mock face template records
    final mockTemplates = <Map<String, String>>[];

    for (int i = 0; i < 50; i++) {
      // Generate employee ID: EMP001, EMP002, ..., EMP050

      mockTemplates.add({
        'employee_id': users[i].employeeId,
        'employee_face_template': base64Template,
      });
    }

    return mockTemplates;
  }
}
