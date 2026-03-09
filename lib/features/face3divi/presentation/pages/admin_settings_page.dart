import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
// import '../../../../core/di/service_locator.dart';
import '../bloc/settings_bloc.dart';
import '../widgets/modern_button.dart';

class AdminSettingsPage extends StatefulWidget {
  const AdminSettingsPage({super.key});

  @override
  State<AdminSettingsPage> createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends State<AdminSettingsPage> {
  late TextEditingController _checkInHourController;
  late TextEditingController _checkInMinuteController;
  late TextEditingController _checkOutHourController;
  late TextEditingController _checkOutMinuteController;
  late TextEditingController _ipPortController;
  late TextEditingController _currentPinController;
  late TextEditingController _newPinController;
  late TextEditingController _confirmPinController;

  // final bool _showCurrentPin = false;
  // final bool _showNewPin = false;
  // final bool _showConfirmPin = false;

  @override
  void initState() {
    super.initState();
    _checkInHourController = TextEditingController(text: '09');
    _checkInMinuteController = TextEditingController(text: '00');
    _checkOutHourController = TextEditingController(text: '18');
    _checkOutMinuteController = TextEditingController(text: '00');
    _ipPortController = TextEditingController(text: '172.21.23.70:81');
    _currentPinController = TextEditingController();
    _newPinController = TextEditingController();
    _confirmPinController = TextEditingController();
  }

  Future<void> _saveApiConfig() async {
    final ipPort = _ipPortController.text.trim();
    if (ipPort.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('IP/Port cannot be empty'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    context.read<SettingsBloc>().add(UpdateApiConfigEvent(ipPort: ipPort));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('API configuration saved'),
        backgroundColor: AppColors.successGreen,
      ),
    );
  }

  Future<void> _saveSettings() async {
    try {
      final checkInHour = int.parse(_checkInHourController.text);
      final checkInMinute = int.parse(_checkInMinuteController.text);
      final checkOutHour = int.parse(_checkOutHourController.text);
      final checkOutMinute = int.parse(_checkOutMinuteController.text);

      // Validate input
      if (checkInHour < 0 ||
          checkInHour > 23 ||
          checkInMinute < 0 ||
          checkInMinute > 59 ||
          checkOutHour < 0 ||
          checkOutHour > 23 ||
          checkOutMinute < 0 ||
          checkOutMinute > 59 ||
          checkOutHour < checkInHour ||
          (checkOutHour == checkInHour && checkOutMinute <= checkInMinute)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid times: Check-out must be after check-in'),
              backgroundColor: AppColors.warningOrange,
            ),
          );
        }
        return;
      }

      // Dispatch the update event to SettingsBloc
      if (mounted) {
        context.read<SettingsBloc>().add(
          UpdateCheckInOutHoursEvent(
            checkInHour: checkInHour,
            checkInMinute: checkInMinute,
            checkOutHour: checkOutHour,
            checkOutMinute: checkOutMinute,
          ),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved successfully'),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving settings: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _checkInHourController.dispose();
    _checkInMinuteController.dispose();
    _checkOutHourController.dispose();
    _checkOutMinuteController.dispose();
    _ipPortController.dispose();
    _currentPinController.dispose();
    _newPinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, settingsState) {
        return _buildContent(settingsState);
      },
    );
  }

  Widget _buildContent(SettingsState settingsState) {
    // Initialize controllers with loaded settings when available
    if (settingsState is SettingsLoaded) {
      _checkInHourController.text = settingsState.settings.checkInHour
          .toString()
          .padLeft(2, '0');
      _checkInMinuteController.text = settingsState.settings.checkInMinute
          .toString()
          .padLeft(2, '0');
      _checkOutHourController.text = settingsState.settings.checkOutHour
          .toString()
          .padLeft(2, '0');
      _checkOutMinuteController.text = settingsState.settings.checkOutMinute
          .toString()
          .padLeft(2, '0');
      _ipPortController.text = settingsState.settings.ipPort;
    }

    // final isFaceRecognitionEnabled = (settingsState is SettingsLoaded)
    //     ? settingsState.settings.faceRecognitionEnabled
    //     : true; // Default to enabled while loading

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Admin Settings',
                style: AppTextStyles.headlineLarge.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Manage attendance rules, PIN security, and system options.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              _buildSettingSection(
                title: 'API Configuration',
                subtitle: 'Set API server IP and port for /auth/login',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('IP:Port', style: AppTextStyles.labelSmall),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _ipPortController,
                      keyboardType: TextInputType.url,
                      decoration: InputDecoration(
                        hintText: '172.21.23.70:81',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Base URL format: http://<IP:PORT>/api/v1_1',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ModernButton(
                  label: 'Save API Config',
                  onPressed: _saveApiConfig,
                ),
              ),
              const SizedBox(height: 32),
              const Divider(thickness: 1),
              const SizedBox(height: 32),
              // Check-in/out hour settings
              _buildSettingSection(
                title: 'Check-In/Out Hour Configuration',
                subtitle: 'Set check-in and check-out times for attendance',
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Check-In Hour',
                                style: AppTextStyles.labelSmall,
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _checkInHourController,
                                keyboardType: TextInputType.number,
                                maxLength: 2,
                                decoration: InputDecoration(
                                  counterText: '',
                                  hintText: '09',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Check-In Minute',
                                style: AppTextStyles.labelSmall,
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _checkInMinuteController,
                                keyboardType: TextInputType.number,
                                maxLength: 2,
                                decoration: InputDecoration(
                                  counterText: '',
                                  hintText: '00',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Check-Out Hour',
                                style: AppTextStyles.labelSmall,
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _checkOutHourController,
                                keyboardType: TextInputType.number,
                                maxLength: 2,
                                decoration: InputDecoration(
                                  counterText: '',
                                  hintText: '18',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Check-Out Minute',
                                style: AppTextStyles.labelSmall,
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _checkOutMinuteController,
                                keyboardType: TextInputType.number,
                                maxLength: 2,
                                decoration: InputDecoration(
                                  counterText: '',
                                  hintText: '00',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ModernButton(
                  label: 'Save Check-In/Out Hours',
                  onPressed: _saveSettings,
                ),
              ),
              const SizedBox(height: 32),
              const Divider(thickness: 1),
              const SizedBox(height: 32),
              // // Change PIN section
              // _buildSettingSection(
              //   title: 'Change Admin PIN',
              //   subtitle: 'Update your administrator access PIN',
              //   child: Column(
              //     children: [
              //       _buildPinField(
              //         label: 'Current PIN',
              //         controller: _currentPinController,
              //         isObscured: !_showCurrentPin,
              //         onToggle: () {
              //           setState(() => _showCurrentPin = !_showCurrentPin);
              //         },
              //       ),
              //       const SizedBox(height: 16),
              //       _buildPinField(
              //         label: 'New PIN',
              //         controller: _newPinController,
              //         isObscured: !_showNewPin,
              //         onToggle: () {
              //           setState(() => _showNewPin = !_showNewPin);
              //         },
              //       ),
              //       const SizedBox(height: 16),
              //       _buildPinField(
              //         label: 'Confirm PIN',
              //         controller: _confirmPinController,
              //         isObscured: !_showConfirmPin,
              //         onToggle: () {
              //           setState(() => _showConfirmPin = !_showConfirmPin);
              //         },
              //       ),
              //     ],
              //   ),
              // ),
              // const SizedBox(height: 24),
              // SizedBox(
              //   width: double.infinity,
              //   child: ModernButton(label: 'Update PIN', onPressed: _updatePin),
              // ),
              // const SizedBox(height: 32),
              // const Divider(thickness: 1),
              // const SizedBox(height: 32),
              // // Other settings
              // _buildSettingSection(
              //   title: 'App Settings',
              //   subtitle: 'General application settings',
              //   child: _buildSettingOption(
              //     icon: Icons.lock,
              //     title: 'Enable Face Recognition',
              //     value: isFaceRecognitionEnabled,
              //     onChanged: (value) {
              //       _saveFaceRecognitionSetting(value);
              //     },
              //   ),
              // ),
              // const SizedBox(height: 32),
              // About section
              _buildSettingSection(
                title: 'About',
                subtitle: 'Application information',
                child: Column(
                  children: [
                    _buildInfoRow('App Version', 'v1.0.0'),
                    const SizedBox(height: 12),
                    _buildInfoRow('Build', '1'),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingSection({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.titleLarge),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: AppColors.backgroundWhite,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.borderLight),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryPurple.withOpacity(0.06),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(padding: const EdgeInsets.all(18), child: child),
        ),
      ],
    );
  }

  // Widget _buildPinField({
  //   required String label,
  //   required TextEditingController controller,
  //   required bool isObscured,
  //   required VoidCallback onToggle,
  // }) {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Text(label, style: AppTextStyles.labelSmall),
  //       const SizedBox(height: 8),
  //       TextFormField(
  //         controller: controller,
  //         maxLength: 6,
  //         keyboardType: TextInputType.number,
  //         obscureText: isObscured,
  //         decoration: InputDecoration(
  //           counterText: '',
  //           hintText: '••••••',
  //           border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
  //           suffix: IconButton(
  //             icon: Icon(
  //               isObscured ? Icons.visibility_off : Icons.visibility,
  //               size: 20,
  //             ),
  //             onPressed: onToggle,
  //           ),
  //         ),
  //       ),
  //     ],
  //   );
  // }

  // Widget _buildSettingOption({
  //   required IconData icon,
  //   required String title,
  //   required bool value,
  //   required ValueChanged<bool> onChanged,
  // }) {
  //   return Row(
  //     children: [
  //       Icon(icon, color: AppColors.primaryPurple),
  //       const SizedBox(width: 16),
  //       Expanded(child: Text(title, style: AppTextStyles.bodyMedium)),
  //       Switch(
  //         value: value,
  //         onChanged: onChanged,
  //         activeThumbColor: AppColors.primaryPurple,
  //       ),
  //     ],
  //   );
  // }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  // void _updatePin() {
  //   if (_currentPinController.text.isEmpty ||
  //       _newPinController.text.isEmpty ||
  //       _confirmPinController.text.isEmpty) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //         content: Text('Please fill all PIN fields'),
  //         backgroundColor: AppColors.errorRed,
  //       ),
  //     );
  //     return;
  //   }

  //   if (_newPinController.text != _confirmPinController.text) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //         content: Text('New PIN and confirmation do not match'),
  //         backgroundColor: AppColors.errorRed,
  //       ),
  //     );
  //     return;
  //   }

  //   if (_newPinController.text.length != 6) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //         content: Text('PIN must be 6 digits'),
  //         backgroundColor: AppColors.errorRed,
  //       ),
  //     );
  //     return;
  //   }

  //   // Verify and update PIN
  //   _verifyAndUpdatePin();
  // }

  // Future<void> _verifyAndUpdatePin() async {
  //   try {
  //     await serviceLocator.adminPinRepository.updatePIN(
  //       currentPin: _currentPinController.text,
  //       newPin: _newPinController.text,
  //       updatedBy: 'Admin',
  //     );

  //     _currentPinController.clear();
  //     _newPinController.clear();
  //     _confirmPinController.clear();

  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(
  //           content: Text('PIN updated successfully'),
  //           backgroundColor: AppColors.successGreen,
  //         ),
  //       );
  //     }
  //   } on Exception catch (e) {
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text(e.toString().replaceFirst('Exception: ', '')),
  //           backgroundColor: AppColors.errorRed,
  //         ),
  //       );
  //     }
  //   }
  // }

  // void _saveFaceRecognitionSetting(bool value) {
  //   // Dispatch the update event to SettingsBloc
  //   context.read<SettingsBloc>().add(UpdateFaceRecognitionEvent(value));

  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(
  //       content: Text('Face Recognition ${value ? 'enabled' : 'disabled'}'),
  //       backgroundColor: AppColors.successGreen,
  //       duration: const Duration(seconds: 1),
  //     ),
  //   );
  // }
}

const Color kErrorColor = Color(0xFFEF4444);
