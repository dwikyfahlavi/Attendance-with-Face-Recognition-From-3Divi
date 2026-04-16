import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_config.dart';
// import '../../../../core/di/service_locator.dart';
import '../bloc/settings_bloc.dart';
import '../widgets/modern_button.dart';

class AdminSettingsPage extends StatefulWidget {
  const AdminSettingsPage({super.key});

  @override
  State<AdminSettingsPage> createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends State<AdminSettingsPage> {
  late TextEditingController _checkInMaxHourController;
  late TextEditingController _checkInMaxMinuteController;
  late TextEditingController _ipPortController;
  late TextEditingController _currentPinController;
  late TextEditingController _newPinController;
  late TextEditingController _confirmPinController;
  late TextEditingController _attendanceCodeController;
  late TextEditingController _unattendanceCodeController;

  // ValueNotifiers for reactive check-in/out time updates
  late ValueNotifier<int> _checkInHourNotifier;
  late ValueNotifier<int> _checkInMinuteNotifier;
  late ValueNotifier<Map<String, int>> _checkOutTimeNotifier;

  // final bool _showCurrentPin = false;
  // final bool _showNewPin = false;
  // final bool _showConfirmPin = false;

  @override
  void initState() {
    super.initState();
    _checkInMaxHourController = TextEditingController(text: '09');
    _checkInMaxMinuteController = TextEditingController(text: '00');
    _ipPortController = TextEditingController(text: '172.21.23.70:81');
    _currentPinController = TextEditingController();
    _newPinController = TextEditingController();
    _confirmPinController = TextEditingController();
    _attendanceCodeController = TextEditingController();
    _unattendanceCodeController = TextEditingController();

    // Initialize ValueNotifiers
    _checkInHourNotifier = ValueNotifier<int>(9);
    _checkInMinuteNotifier = ValueNotifier<int>(0);
    _checkOutTimeNotifier = ValueNotifier<Map<String, int>>({
      'hour': 9,
      'minute': 1,
    });

    // Add listeners to update check-out time reactively
    _checkInHourNotifier.addListener(_updateCheckOutTime);
    _checkInMinuteNotifier.addListener(_updateCheckOutTime);

    // Add listeners to text controllers to sync with ValueNotifiers
    _checkInMaxHourController.addListener(() {
      try {
        final value = int.parse(_checkInMaxHourController.text);
        if (value >= 0 && value <= 23) {
          _checkInHourNotifier.value = value;
        }
      } catch (_) {}
    });

    _checkInMaxMinuteController.addListener(() {
      try {
        final value = int.parse(_checkInMaxMinuteController.text);
        if (value >= 0 && value <= 59) {
          _checkInMinuteNotifier.value = value;
        }
      } catch (_) {}
    });
  }

  /// Update check-out time when check-in time changes
  void _updateCheckOutTime() {
    final outTime = _calculateCheckOutTime(
      _checkInHourNotifier.value,
      _checkInMinuteNotifier.value,
    );
    _checkOutTimeNotifier.value = outTime;
  }

  /// Calculate check-out time as check-in max time + 1 minute
  Map<String, int> _calculateCheckOutTime(int checkInHour, int checkInMinute) {
    int outHour = checkInHour;
    int outMinute = checkInMinute + 1;

    // If minute exceeds 59, increment hour
    if (outMinute > 59) {
      outMinute = 0;
      outHour = (outHour + 1) % 24;
    }

    return {'hour': outHour, 'minute': outMinute};
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
      final checkInMaxHour = int.parse(_checkInMaxHourController.text);
      final checkInMaxMinute = int.parse(_checkInMaxMinuteController.text);

      // Validate input
      if (checkInMaxHour < 0 ||
          checkInMaxHour > 23 ||
          checkInMaxMinute < 0 ||
          checkInMaxMinute > 59) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid time format'),
              backgroundColor: AppColors.warningOrange,
            ),
          );
        }
        return;
      }

      // Get check-out time from ValueNotifier
      final checkOutTime = _checkOutTimeNotifier.value;

      // Dispatch the update event to SettingsBloc
      if (mounted) {
        context.read<SettingsBloc>().add(
          UpdateCheckInOutHoursEvent(
            checkInHour: checkInMaxHour,
            checkInMinute: checkInMaxMinute,
            checkOutHour: checkOutTime['hour']!,
            checkOutMinute: checkOutTime['minute']!,
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
    _checkInMaxHourController.dispose();
    _checkInMaxMinuteController.dispose();
    _ipPortController.dispose();
    _currentPinController.dispose();
    _newPinController.dispose();
    _confirmPinController.dispose();

    // Dispose ValueNotifiers
    _checkInHourNotifier.dispose();
    _checkInMinuteNotifier.dispose();
    _checkOutTimeNotifier.dispose();

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
      _checkInMaxHourController.text = settingsState.settings.checkInHour
          .toString()
          .padLeft(2, '0');
      _checkInMaxMinuteController.text = settingsState.settings.checkInMinute
          .toString()
          .padLeft(2, '0');
      _ipPortController.text = settingsState.settings.ipPort;
      _attendanceCodeController.text =
          settingsState.settings.attendanceCode ?? '';
      _unattendanceCodeController.text =
          settingsState.settings.unattendanceCode ?? '';
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
              // Check-in max time configuration
              _buildSettingSection(
                title: 'Check-In Maximum Time Configuration',
                subtitle:
                    'Set maximum check-in time. Check-out will be automatically set to +1 minute.',
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Check-In Max Hour',
                                style: AppTextStyles.labelSmall,
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _checkInMaxHourController,
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
                                'Check-In Max Minute',
                                style: AppTextStyles.labelSmall,
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _checkInMaxMinuteController,
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
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundLight,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Auto-Calculated Check-Out Time (Max Check-In + 1 minute)',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                  horizontal: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryPurple.withOpacity(
                                    0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Read-only',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.primaryPurple,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ValueListenableBuilder<Map<String, int>>(
                            valueListenable: _checkOutTimeNotifier,
                            builder: (context, checkOutTime, _) {
                              return Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Check-Out Hour',
                                          style: AppTextStyles.labelSmall,
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12,
                                            horizontal: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.backgroundWhite,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: AppColors.borderLight,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  checkOutTime['hour']!
                                                      .toString()
                                                      .padLeft(2, '0'),
                                                  style: AppTextStyles
                                                      .bodyMedium
                                                      .copyWith(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                ),
                                              ),
                                              Icon(
                                                Icons.lock,
                                                size: 16,
                                                color: AppColors.textSecondary,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Check-Out Minute',
                                          style: AppTextStyles.labelSmall,
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12,
                                            horizontal: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.backgroundWhite,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: AppColors.borderLight,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  checkOutTime['minute']!
                                                      .toString()
                                                      .padLeft(2, '0'),
                                                  style: AppTextStyles
                                                      .bodyMedium
                                                      .copyWith(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                ),
                                              ),
                                              Icon(
                                                Icons.lock,
                                                size: 16,
                                                color: AppColors.textSecondary,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ModernButton(
                  label: 'Save Check-In Max Time',
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
                    _buildInfoRow('App Version', AppConfig.appVersion),
                    const SizedBox(height: 12),
                    _buildInfoRow('Build', AppConfig.buildNumber),
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
