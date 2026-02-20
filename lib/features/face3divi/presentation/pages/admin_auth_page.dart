import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:camera/camera.dart';
import '../bloc/admin_auth_bloc.dart';
import '../bloc/user_session_bloc.dart';
import '../bloc/settings_bloc.dart';
import '../../../../core/services/permission_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../widgets/modern_button.dart';

class AdminAuthPage extends StatefulWidget {
  const AdminAuthPage({super.key});

  @override
  State<AdminAuthPage> createState() => _AdminAuthPageState();
}

class _AdminAuthPageState extends State<AdminAuthPage> {
  late PageController _pageController;
  late TextEditingController _pinController;

  CameraController? _cameraController;
  late Future<void> _initializeCameraFuture;
  bool _isCameraReady = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pinController = TextEditingController();
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

      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No camera found'),
              backgroundColor: AppColors.errorRed,
            ),
          );
        }
        return;
      }

      // Use front camera for face recognition
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

  @override
  void dispose() {
    _pageController.dispose();
    _pinController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AdminAuthBloc, AdminAuthState>(
      listener: (context, state) {
        if (state is AdminAuthSuccess) {
          // If user is available (face auth), store in session
          if (state.user != null) {
            context.read<UserSessionBloc>().add(UserLoggedInEvent(state.user!));
          }
          // Navigate to admin dashboard
          Navigator.of(context).pushReplacementNamed('/admin/dashboard');
        } else if (state is AdminAuthFailed) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.reason),
              backgroundColor: AppColors.errorRed,
            ),
          );
        }
      },
      child: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, settingsState) {
          final isFaceRecognitionEnabled = (settingsState is SettingsLoaded)
              ? settingsState.settings.faceRecognitionEnabled
              : true; // Default to enabled while loading

          return Scaffold(
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            body: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.backgroundLight,
                        AppColors.backgroundWhite,
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: -60,
                  right: -40,
                  child: _SoftBlob(
                    size: 180,
                    color: AppColors.primaryPurple.withOpacity(0.18),
                  ),
                ),
                Positioned(
                  bottom: -80,
                  left: -20,
                  child: _SoftBlob(
                    size: 220,
                    color: AppColors.secondaryCyan.withOpacity(0.14),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        Text(
                          'Admin Access',
                          style: AppTextStyles.displaySmall.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isFaceRecognitionEnabled
                              ? 'Secure your session with a PIN or face verification.'
                              : 'Secure your session with your admin PIN.',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (isFaceRecognitionEnabled)
                          _AuthModePill(controller: _pageController),
                        if (isFaceRecognitionEnabled)
                          const SizedBox(height: 20),
                        Expanded(
                          child: PageView(
                            controller: _pageController,
                            physics: isFaceRecognitionEnabled
                                ? const PageScrollPhysics()
                                : const NeverScrollableScrollPhysics(),
                            children: [
                              _buildPinAuthPage(
                                context,
                                isFaceRecognitionEnabled,
                              ),
                              if (isFaceRecognitionEnabled)
                                _buildFaceAuthPage(context),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPinAuthPage(
    BuildContext context,
    bool isFaceRecognitionEnabled,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        children: [
          _AuthCard(
            title: 'PIN Verification',
            subtitle: 'Enter your 6-digit admin PIN to continue.',
            child: BlocBuilder<AdminAuthBloc, AdminAuthState>(
              builder: (context, state) {
                String? errorText;
                if (state is AdminAuthFailed) {
                  errorText = state.reason;
                }

                return Column(
                  children: [
                    PinInputField(
                      controller: _pinController,
                      enabled: state is! AdminAuthLoading,
                      errorText: errorText,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ModernButton(
                        label: state is AdminAuthLoading
                            ? 'Verifying...'
                            : 'Continue',
                        onPressed: () {
                          if (_pinController.text.isNotEmpty) {
                            context.read<AdminAuthBloc>().add(
                              AuthenticateWithPINEvent(_pinController.text),
                            );
                          }
                        },
                        isLoading: state is AdminAuthLoading,
                        isEnabled: state is! AdminAuthLoading,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          if (isFaceRecognitionEnabled)
            _SoftNote(
              icon: Icons.face,
              text: 'Prefer face verification? Switch to the next tab.',
            ),
        ],
      ),
    );
  }

  Widget _buildFaceAuthPage(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        children: [
          _AuthCard(
            title: 'Face Verification',
            subtitle: 'Center your face in the frame to verify.',
            child: Column(
              children: [
                Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    color: AppColors.backgroundWhite,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: AppColors.borderLight,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryPurple.withOpacity(0.08),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: FutureBuilder<void>(
                    future: _initializeCameraFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done &&
                          _isCameraReady) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(26),
                          child: CameraPreview(_cameraController!),
                        );
                      } else if (snapshot.hasError) {
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error,
                              color: AppColors.errorRed,
                              size: 32,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Camera Error',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.errorRed,
                              ),
                            ),
                          ],
                        );
                      } else {
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.face,
                              size: 64,
                              color: AppColors.primaryPurple.withOpacity(0.4),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Preparing camera...',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(height: 20),
                BlocBuilder<AdminAuthBloc, AdminAuthState>(
                  builder: (context, state) {
                    return Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ModernButton(
                            label: state is AdminAuthLoading
                                ? 'Verifying...'
                                : 'Start Verification',
                            onPressed: () {
                              context.read<AdminAuthBloc>().add(
                                AuthenticateWithFaceEvent('test_nik'),
                              );
                            },
                            isLoading: state is AdminAuthLoading,
                            isEnabled: state is! AdminAuthLoading,
                          ),
                        ),
                        if (state is AdminAuthFailed)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Text(
                              state.reason,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.errorRed,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ModernButton(
                    label: 'Use PIN Instead',
                    onPressed: () {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                      );
                    },
                    isPrimary: false,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SoftNote(
            icon: Icons.lock_outline,
            text: 'Face access uses the device camera. Good lighting helps.',
          ),
        ],
      ),
    );
  }
}

class _SoftBlob extends StatelessWidget {
  final double size;
  final Color color;

  const _SoftBlob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _AuthModePill extends StatefulWidget {
  final PageController controller;

  const _AuthModePill({required this.controller});

  @override
  State<_AuthModePill> createState() => _AuthModePillState();
}

class _AuthModePillState extends State<_AuthModePill> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(children: [_pillButton('PIN', 0), _pillButton('Face', 1)]),
    );
  }

  Widget _pillButton(String label, int index) {
    final isActive = _index == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _index = index);
          widget.controller.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primaryPurple.withOpacity(0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              label,
              style: AppTextStyles.labelLarge.copyWith(
                color: isActive
                    ? AppColors.primaryPurple
                    : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _AuthCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryPurple.withOpacity(0.08),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.headlineMedium.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

class _SoftNote extends StatelessWidget {
  final IconData icon;
  final String text;

  const _SoftNote({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryPurple),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Reusable PIN input field component
class PinInputField extends StatefulWidget {
  final TextEditingController controller;
  final bool enabled;
  final String? errorText;
  final VoidCallback? onComplete;

  const PinInputField({
    super.key,
    required this.controller,
    this.enabled = true,
    this.errorText,
    this.onComplete,
  });

  @override
  State<PinInputField> createState() => _PinInputFieldState();
}

class _PinInputFieldState extends State<PinInputField> {
  bool _showPin = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: widget.controller,
          enabled: widget.enabled,
          maxLength: 6,
          keyboardType: TextInputType.number,
          obscureText: !_showPin,
          textAlign: TextAlign.center,
          style: AppTextStyles.headlineSmall.copyWith(
            letterSpacing: 8,
            color: AppColors.primaryPurple,
          ),
          decoration: InputDecoration(
            counterText: '',
            hintText: '••••••',
            hintStyle: AppTextStyles.headlineSmall.copyWith(
              color: AppColors.textSecondary.withOpacity(0.3),
              letterSpacing: 8,
            ),
            filled: true,
            fillColor: AppColors.backgroundWhite,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: AppColors.primaryPurple,
                width: 2,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: AppColors.primaryPurple,
                width: 2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: AppColors.secondary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.errorRed, width: 2),
            ),
            suffix: IconButton(
              icon: Icon(
                _showPin ? Icons.visibility_off : Icons.visibility,
                color: AppColors.primaryPurple,
              ),
              onPressed: widget.enabled
                  ? () {
                      setState(() => _showPin = !_showPin);
                    }
                  : null,
            ),
          ),
          onChanged: (value) {
            if (value.length == 6 && widget.onComplete != null) {
              widget.onComplete!();
            }
          },
        ),
        if (widget.errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              widget.errorText!,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.errorRed,
              ),
            ),
          ),
      ],
    );
  }
}
