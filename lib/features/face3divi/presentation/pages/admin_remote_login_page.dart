import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../bloc/admin_remote_login_bloc.dart';
import '../widgets/modern_button.dart';

class AdminRemoteLoginPage extends StatefulWidget {
  const AdminRemoteLoginPage({super.key});

  @override
  State<AdminRemoteLoginPage> createState() => _AdminRemoteLoginPageState();
}

class _AdminRemoteLoginPageState extends State<AdminRemoteLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _showPassword = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submitLogin() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.read<AdminRemoteLoginBloc>().add(
      LoginRequested(_usernameController.text, _passwordController.text),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AdminRemoteLoginBloc, AdminRemoteLoginState>(
      listener: (context, state) {
        if (state is AdminRemoteLoginSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Login success. Welcome, ${state.user}!'),
              backgroundColor: AppColors.successGreen,
            ),
          );
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/admin/dashboard',
            arguments: state.user,
            (route) => false,
          );
        } else if (state is AdminRemoteLoginError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.errorRed,
            ),
          );
        }
      },
      child: BlocBuilder<AdminRemoteLoginBloc, AdminRemoteLoginState>(
        builder: (context, state) {
          final isLoading = state is AdminRemoteLoginLoading;
          return Scaffold(
            extendBodyBehindAppBar: true,
            // appBar: AppBar(
            //   backgroundColor: Colors.transparent,
            //   elevation: 0,
            //   leading: IconButton(
            //     icon: const Icon(Icons.arrow_back, color: Colors.white),
            //     onPressed: () => Navigator.of(context).pop(),
            //   ),
            // ),
            body: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(gradient: AppColors.primaryGradient),
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 32),
                      // Header Icon
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.security,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Title
                      Text(
                        'Login Portal',
                        style: AppTextStyles.displayMedium.copyWith(
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),

                      // Subtitle
                      Text(
                        'Face Recognition Admin Panel',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),

                      // Description
                      Text(
                        'Manage users, view attendance reports, and sync data from the cloud.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white60,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 48),

                      // Login Card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 30,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Login Credentials',
                                style: AppTextStyles.headlineSmall.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Enter your API credentials to access the admin panel',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Username Field
                              TextFormField(
                                controller: _usernameController,
                                enabled: !isLoading,
                                decoration: InputDecoration(
                                  labelText: 'Username',
                                  prefixIcon: Icon(
                                    Icons.person_outline,
                                    color: AppColors.primaryPurple,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: AppColors.primaryPurple,
                                      width: 1.5,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: AppColors.borderLight,
                                      width: 1,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: AppColors.primaryPurple,
                                      width: 2,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: AppColors.backgroundWhite,
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Username is required';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Password Field
                              TextFormField(
                                controller: _passwordController,
                                enabled: !isLoading,
                                obscureText: !_showPassword,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: Icon(
                                    Icons.lock_outline,
                                    color: AppColors.primaryPurple,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _showPassword
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      color: AppColors.primaryPurple,
                                    ),
                                    onPressed: !isLoading
                                        ? () {
                                            setState(
                                              () => _showPassword =
                                                  !_showPassword,
                                            );
                                          }
                                        : null,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: AppColors.primaryPurple,
                                      width: 1.5,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: AppColors.borderLight,
                                      width: 1,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: AppColors.primaryPurple,
                                      width: 2,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: AppColors.backgroundWhite,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Password is required';
                                  }
                                  if (value.length < 6) {
                                    return 'Password must be at least 6 characters';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),

                              // Login Button
                              SizedBox(
                                width: double.infinity,
                                child: ModernButton(
                                  label: isLoading ? 'Logging in...' : 'Login',
                                  onPressed: isLoading ? () {} : _submitLogin,
                                  isLoading: isLoading,
                                  isEnabled: !isLoading,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // IP Settings Button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: isLoading
                              ? null
                              : () => Navigator.of(
                                  context,
                                ).pushNamed('/admin/settings'),
                          icon: const Icon(Icons.settings),
                          label: const Text('Configure API Server'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(
                              color: Colors.white,
                              width: 1.5,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Security Note
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info, color: Colors.white70, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Your credentials are securely encrypted',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
