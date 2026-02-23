import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import 'dart:typed_data';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/services/permission_service.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../models/user_model.dart';
import '../widgets/modern_button.dart';
import '../bloc/user_registration_bloc.dart';

class AdminRegistrationPage extends StatelessWidget {
  const AdminRegistrationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => UserRegistrationBloc(
        userRepository: serviceLocator.userRepository,
        faceSdkRepository: serviceLocator.faceSdkRepository,
      ),
      child: const _AdminRegistrationPageContent(),
    );
  }
}

class _AdminRegistrationPageContent extends StatefulWidget {
  const _AdminRegistrationPageContent();

  @override
  State<_AdminRegistrationPageContent> createState() =>
      _AdminRegistrationPageContentState();
}

class _AdminRegistrationPageContentState
    extends State<_AdminRegistrationPageContent> {
  final TextEditingController _nikController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  CameraController? _cameraController;
  Future<void>? _initializeCameraFuture;

  String? _selectedDepartment;
  String? _photoPath;
  Uint8List? _capturedImageBytes;
  double? _qualityScore;
  bool _isCameraReady = false;
  int _currentStep = 0;

  final List<String> _departments = [
    'HR',
    'IT',
    'Finance',
    'Operations',
    'Sales',
    'Other',
  ];

  @override
  void initState() {
    super.initState();

    // Delay initialization until after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeCameraAndFaceSDK();
    });
  }

  Future<void> _initializeCameraAndFaceSDK() async {
    // Important: Give extra time for any previous Face SDK resources to fully dispose
    // This prevents license conflicts when navigating from attendance scan page
    await Future.delayed(const Duration(milliseconds: 800));

    // Start Face SDK capture initialization via BLoC
    if (mounted) {
      context.read<UserRegistrationBloc>().add(StartFaceCaptureEvent());
    }

    // Initialize camera
    _initializeCameraFuture = _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      // Request camera permission first
      final permissionGranted =
          await PermissionService.requestCameraPermission();

      if (!permissionGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Camera permission denied. Enable it in app settings.',
              ),
              backgroundColor: AppColors.errorRed,
              action: SnackBarAction(
                label: 'Settings',
                onPressed: () => PermissionService.openAppSettings(),
              ),
            ),
          );
        }
        return;
      }

      // Get available cameras
      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No camera found on this device'),
              backgroundColor: AppColors.errorRed,
            ),
          );
        }
        return;
      }

      // Use front camera if available for face recognition
      final camera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isCameraReady = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error initializing camera: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _capturePhoto() async {
    try {
      if (_cameraController == null || !_isCameraReady) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Camera is not ready'),
            backgroundColor: AppColors.errorRed,
          ),
        );
        return;
      }

      final image = await _cameraController!.takePicture();

      if (!mounted) return;

      setState(() {
        _photoPath = image.path;
      });

      // Process photo via BLoC
      context.read<UserRegistrationBloc>().add(
        CaptureFacePhotoEvent(image.path),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error capturing photo: $e'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  @override
  void dispose() {
    _nikController.dispose();
    _nameController.dispose();
    _departmentController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  void _registerMember() {
    if ((_formKey.currentState?.validate() ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    if (_photoPath == null || _capturedImageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please capture and verify a photo'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    // Register via BLoC
    context.read<UserRegistrationBloc>().add(
      RegisterUserEvent(
        user: RegisteredUser(
          nik: _nikController.text.trim(),
          nama: _nameController.text.trim(),
          department: _selectedDepartment,
          isAdmin: false,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<UserRegistrationBloc, UserRegistrationState>(
      listener: (context, state) {
        if (state is FacePhotoProcessed) {
          // Photo processed successfully
          setState(() {
            _capturedImageBytes = state.croppedFaceBytes;
            _qualityScore = state.qualityScore;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Face detected! Quality: ${(state.qualityScore * 100).toStringAsFixed(0)}%',
              ),
              backgroundColor: AppColors.successGreen,
            ),
          );
        } else if (state is FacePhotoError) {
          // Photo processing failed
          setState(() {
            _photoPath = null;
            _capturedImageBytes = null;
          });

          final errorMsg = state.message;
          final isLicenseError =
              errorMsg.contains('license') ||
              errorMsg.contains('License') ||
              errorMsg.contains('conflict');

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.errorRed,
              duration: Duration(seconds: isLicenseError ? 5 : 3),
              action: isLicenseError
                  ? SnackBarAction(
                      label: 'Retry',
                      textColor: Colors.white,
                      onPressed: () {
                        context.read<UserRegistrationBloc>().add(
                          StartFaceCaptureEvent(),
                        );
                      },
                    )
                  : null,
            ),
          );
        } else if (state is UserRegistrationSuccess) {
          // Registration successful
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.successGreen,
            ),
          );

          // Clear form and navigate back
          _formKey.currentState?.reset();
          _nikController.clear();
          _nameController.clear();
          setState(() {
            _photoPath = null;
            _capturedImageBytes = null;
            _selectedDepartment = null;
            _currentStep = 0;
          });

          Navigator.of(context).pop();
        } else if (state is UserRegistrationError) {
          // Registration failed
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.errorRed,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Register New Member'),
          elevation: 0,
          backgroundColor: AppColors.backgroundWhite,
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.backgroundLight, AppColors.backgroundWhite],
            ),
          ),
          child: BlocBuilder<UserRegistrationBloc, UserRegistrationState>(
            builder: (context, state) {
              // Show loading for multiple states
              if (state is UserRegistrationLoading ||
                  state is FacePhotoProcessing ||
                  state is FaceCaptureLoading) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Processing...'),
                    ],
                  ),
                );
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Step indicator
                    _buildStepIndicator(),
                    const SizedBox(height: 32),

                    // Step content
                    if (_currentStep == 0)
                      _buildMemberFormStep()
                    else
                      _buildPhotoVerificationStep(),

                    const SizedBox(height: 32),

                    // Navigation buttons
                    _buildNavigationButtons(),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStepCircle(0, 'Member Info'),
        Container(
          width: 60,
          height: 2,
          color: _currentStep >= 1
              ? AppColors.secondary
              : AppColors.textSecondary.withOpacity(0.3),
        ),
        _buildStepCircle(1, 'Face Capture'),
      ],
    );
  }

  Widget _buildStepCircle(int step, String label) {
    final isActive = _currentStep >= step;
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive
                ? AppColors.primaryPurple.withOpacity(0.2)
                : AppColors.borderLight,
          ),
          child: Center(
            child: Text(
              '${step + 1}',
              style: AppTextStyles.bodyMedium.copyWith(
                color: isActive
                    ? AppColors.primaryPurple
                    : AppColors.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildMemberFormStep() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Member Information', style: AppTextStyles.headlineSmall),
              const SizedBox(height: 20),

              // NIK field
              TextFormField(
                controller: _nikController,
                decoration: InputDecoration(
                  labelText: 'NIK (Employee ID)',
                  hintText: '1234567890',
                  prefixIcon: const Icon(Icons.badge),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.secondary),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'NIK is required';
                  if (value.length < 5) {
                    return 'NIK must be at least 5 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Name field
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  hintText: 'John Doe',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.secondary),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Name is required';
                  if (value.length < 3) {
                    return 'Name must be at least 3 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Department dropdown
              Text('Department', style: AppTextStyles.bodyMedium),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.secondary),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedDepartment,
                  hint: Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Text(
                      'Select Department',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  underline: const SizedBox(),
                  items: _departments.map((String dept) {
                    return DropdownMenuItem<String>(
                      value: dept,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: Text(dept),
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() => _selectedDepartment = newValue);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoVerificationStep() {
    return Column(
      children: [
        // Photo capture section
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Capture Face Photo', style: AppTextStyles.headlineSmall),
                const SizedBox(height: 20),

                // Camera preview or photo display
                AspectRatio(
                  aspectRatio: 3 / 4,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.backgroundWhite.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.secondary, width: 2),
                    ),
                    child: _capturedImageBytes != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.memory(
                              _capturedImageBytes!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : (_photoPath != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Image.file(
                                    File(_photoPath!),
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : FutureBuilder<void>(
                                  future: _initializeCameraFuture,
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                            ConnectionState.done &&
                                        _isCameraReady) {
                                      return ClipRRect(
                                        borderRadius: BorderRadius.circular(14),
                                        child: OverflowBox(
                                          alignment: Alignment.center,
                                          child: FittedBox(
                                            fit: BoxFit.cover,
                                            child: SizedBox(
                                              width: _cameraController!
                                                  .value
                                                  .previewSize!
                                                  .height,
                                              height: _cameraController!
                                                  .value
                                                  .previewSize!
                                                  .width,
                                              child: CameraPreview(
                                                _cameraController!,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    } else if (snapshot.hasError) {
                                      return Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.error,
                                            color: AppColors.errorRed,
                                            size: 48,
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            'Camera Error',
                                            style: AppTextStyles.bodyMedium
                                                .copyWith(
                                                  color: AppColors.errorRed,
                                                ),
                                          ),
                                        ],
                                      );
                                    } else {
                                      return Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const CircularProgressIndicator(
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  AppColors.secondary,
                                                ),
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            'Starting camera...',
                                            style: AppTextStyles.bodyMedium
                                                .copyWith(
                                                  color: AppColors.secondary,
                                                ),
                                          ),
                                        ],
                                      );
                                    }
                                  },
                                )),
                  ),
                ),
                const SizedBox(height: 16),

                // Quality indicator
                if (_qualityScore != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _qualityScore! >= 0.7
                          ? AppColors.successGreen.withOpacity(0.1)
                          : (_qualityScore! >= 0.5
                                ? AppColors.secondary.withOpacity(0.1)
                                : AppColors.errorRed.withOpacity(0.1)),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _qualityScore! >= 0.7
                            ? AppColors.successGreen
                            : (_qualityScore! >= 0.5
                                  ? AppColors.secondary
                                  : AppColors.errorRed),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _qualityScore! >= 0.7
                              ? Icons.check_circle
                              : (_qualityScore! >= 0.5
                                    ? Icons.info
                                    : Icons.warning),
                          color: _qualityScore! >= 0.7
                              ? AppColors.successGreen
                              : (_qualityScore! >= 0.5
                                    ? AppColors.secondary
                                    : AppColors.errorRed),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Face Quality Score',
                                style: AppTextStyles.bodySmall.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${(_qualityScore! * 100).toStringAsFixed(0)}% - ${_qualityScore! >= 0.7 ? 'Excellent' : (_qualityScore! >= 0.5 ? 'Good' : 'Poor')}',
                                style: AppTextStyles.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Capture button
                SizedBox(
                  width: double.infinity,
                  child: ModernButton(
                    label: _capturedImageBytes != null
                        ? 'Retake Photo'
                        : 'Capture Photo',
                    onPressed: () {
                      if (_capturedImageBytes != null) {
                        // Reset to retake
                        setState(() {
                          _photoPath = null;
                          _capturedImageBytes = null;
                          _qualityScore = null;
                        });
                      } else {
                        _capturePhoto();
                      }
                    },
                    isEnabled: _isCameraReady || _capturedImageBytes != null,
                  ),
                ),

                // Instructions
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: AppColors.secondary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Ensure good lighting and face the camera directly',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.secondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      children: [
        if (_currentStep > 0)
          Expanded(
            child: SizedBox(
              height: 52,
              child: OutlinedButton(
                onPressed: () {
                  setState(() => _currentStep--);
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.secondary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Back',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.secondary,
                  ),
                ),
              ),
            ),
          ),
        if (_currentStep > 0) const SizedBox(width: 16),
        Expanded(
          child: ModernButton(
            label: _currentStep == 0 ? 'Next' : 'Register Member',
            onPressed: _currentStep == 0
                ? () {
                    if (_formKey.currentState?.validate() ?? false) {
                      setState(() => _currentStep++);
                    }
                  }
                : _registerMember,
          ),
        ),
      ],
    );
  }
}
