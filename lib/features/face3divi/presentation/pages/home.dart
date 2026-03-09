import 'package:flutter/material.dart';
import 'package:fr3divi/core/theme/app_colors.dart';
import 'package:fr3divi/core/theme/app_text_styles.dart';
import '../widgets/modern_button.dart';

/// Simplified HomePage for the new attendance system
/// Shows role-based navigation (Admin/User)
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.primaryGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo/Header
                Icon(Icons.face, size: 80, color: Colors.white),
                const SizedBox(height: 24),

                Text(
                  'Attendance System',
                  style: AppTextStyles.displayMedium.copyWith(
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                Text(
                  'Face Recognition & Real-time Attendance',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // Main action buttons
                ModernButton(
                  label: 'Mark Attendance',
                  onPressed: () {
                    Navigator.of(context).pushNamed('/attendance');
                  },
                  icon: Icons.camera_alt,
                  width: double.infinity,
                ),
                const SizedBox(height: 16),

                ModernButton(
                  label: 'Admin Panel',
                  onPressed: () {
                    Navigator.of(context).pushNamed('/admin/login-api');
                  },
                  icon: Icons.admin_panel_settings,
                  width: double.infinity,
                ),
                const SizedBox(height: 16),

                // ModernButton(
                //   label: 'View History',
                //   onPressed: () {
                //     Navigator.of(context).pushNamed('/attendance/history');
                //   },
                //   icon: Icons.history,
                //   width: double.infinity,
                //   isPrimary: false,
                // ),
                const Spacer(),

                // Version info
                Text(
                  'Version 2.0 - Modern Attendance System',
                  style: AppTextStyles.caption.copyWith(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
