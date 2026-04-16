import 'package:flutter/material.dart';
import 'package:fr3divi/core/constants/app_config.dart';
import 'package:fr3divi/core/theme/app_colors.dart';
import 'package:fr3divi/core/theme/app_text_styles.dart';

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(gradient: AppColors.primaryGradient),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Logo/Header
              const SizedBox(height: 60),
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
                style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              Spacer(),

              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              SizedBox(height: 24),
              Text(
                'Initializing...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),

              // Version info
              Text(
                'Version ${AppConfig.fullVersion} - Modern Attendance System',
                style: AppTextStyles.caption.copyWith(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
