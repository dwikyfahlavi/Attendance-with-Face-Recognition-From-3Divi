import '../../features/face3divi/data/data_source/absen_local_data_source.dart';
import '../../features/face3divi/data/repository/absen_repository.dart';
import '../../features/face3divi/data/repository/admin_pin_repository.dart';
import '../../features/face3divi/data/data_source/face_sdk_data_source.dart';
import '../../features/face3divi/data/repository/face_sdk_repository.dart';
import '../../features/face3divi/data/face_verification_service.dart';
import '../../features/face3divi/data/repository/settings_repository.dart';
import '../../features/face3divi/data/data_source/remote_auth_data_source.dart';
import '../../features/face3divi/data/repository/remote_auth_repository.dart';
import '../../features/face3divi/data/data_source/user_local_data_source.dart';
import '../../features/face3divi/data/repository/user_repository.dart';
import '../../features/face3divi/data/models/user_model.dart';
import '../../features/face3divi/data/models/absen_model.dart';
import '../../features/face3divi/data/models/admin_pin_model.dart';
import '../../features/face3divi/data/models/settings_model.dart';
import '../services/camera_service.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../features/face3divi/data/hive_boxes.dart';

/// Manual service locator for dependency injection
/// Replace GetIt/Injectable with simple factory functions
class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();

  factory ServiceLocator() {
    return _instance;
  }

  ServiceLocator._internal();

  // Cached instances
  late final Box<RegisteredUser> _userBox;
  late final Box<AbsenModel> _absenBox;
  late final Box<AdminPinModel> _adminPinBox;
  late final Box<SettingsModel> _settingsBox;
  late final CameraService _cameraService;
  late final FaceSdkDataSource _faceSdkDataSource;
  late final FaceSdkRepository _faceSdkRepository;
  FaceVerificationService? _faceVerificationService;
  late final UserLocalDataSource _userLocalDataSource;
  late final UserRepository _userRepository;
  late final AbsenLocalDataSource _absenLocalDataSource;
  late final AbsenRepository _absenRepository;
  late final AdminPinRepository _adminPinRepository;
  late final SettingsRepository _settingsRepository;
  late final RemoteAuthDataSource _remoteAuthDataSource;
  late final RemoteAuthRepository _remoteAuthRepository;

  /// Initialize the service locator - call this once during app startup
  Future<void> setup() async {
    // Initialize Hive boxes
    _userBox = HiveBoxes.userBox;
    _absenBox = HiveBoxes.absenBox;
    _adminPinBox = HiveBoxes.adminPinBox;
    _settingsBox = HiveBoxes.settingsBox;

    // Initialize camera service
    _cameraService = CameraService();

    // Initialize data layer
    _faceSdkDataSource = FaceSdkDataSource();
    _faceSdkRepository = FaceSdkRepository(_faceSdkDataSource);

    _userLocalDataSource = UserLocalDataSource(_userBox);
    _userRepository = UserRepository(_userLocalDataSource);

    _absenLocalDataSource = AbsenLocalDataSource(_absenBox);
    _absenRepository = AbsenRepository(_absenLocalDataSource, _userRepository);

    _adminPinRepository = AdminPinRepository(_adminPinBox);
    await _adminPinRepository.initializeDefaultPin();

    // FaceVerificationService will be set after Face SDK session is ready.
    _faceVerificationService = null;

    // Initialize Settings Repository
    _settingsRepository = SettingsRepository(_settingsBox);

    // Initialize Remote Auth
    _remoteAuthDataSource = RemoteAuthDataSource();
    _remoteAuthRepository = RemoteAuthRepository(
      settingsRepository: _settingsRepository,
      userRepository: _userRepository,
      remoteAuthDataSource: _remoteAuthDataSource,
    );
  }

  // Getters for services
  Box<RegisteredUser> get userBox => _userBox;
  Box<AbsenModel> get absenBox => _absenBox;
  Box<AdminPinModel> get adminPinBox => _adminPinBox;
  Box<SettingsModel> get settingsBox => _settingsBox;
  CameraService get cameraService => _cameraService;
  FaceSdkDataSource get faceSdkDataSource => _faceSdkDataSource;
  FaceSdkRepository get faceSdkRepository => _faceSdkRepository;
  FaceVerificationService? get faceVerificationService =>
      _faceVerificationService;
  void setFaceVerificationService(FaceVerificationService? service) {
    _faceVerificationService = service;
  }

  UserLocalDataSource get userLocalDataSource => _userLocalDataSource;
  UserRepository get userRepository => _userRepository;
  AbsenLocalDataSource get absenLocalDataSource => _absenLocalDataSource;
  AbsenRepository get absenRepository => _absenRepository;
  AdminPinRepository get adminPinRepository => _adminPinRepository;
  SettingsRepository get settingsRepository => _settingsRepository;
  RemoteAuthRepository get remoteAuthRepository => _remoteAuthRepository;
}

/// Convenience getter
final serviceLocator = ServiceLocator();
