import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../bloc/admin_remote_login_bloc.dart'; // New import
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
            appBar: AppBar(
              title: const Text('Admin Login'),
              elevation: 0,
              backgroundColor: AppColors.backgroundWhite,
            ),
            body: Container(
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
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('API Login', style: AppTextStyles.headlineLarge),
                        const SizedBox(height: 8),
                        Text(
                          'Login to API and sync user to local Hive storage.',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _usernameController,
                          decoration: InputDecoration(
                            labelText: 'Username',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Username is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Password is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: isLoading
                                ? null
                                : () => Navigator.of(
                                    context,
                                  ).pushNamed('/admin/settings'),
                            icon: const Icon(Icons.settings),
                            label: const Text('IP Settings'),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ModernButton(
                            label: 'Login',
                            onPressed: isLoading ? () {} : _submitLogin,
                            isLoading: isLoading,
                          ),
                        ),
                      ],
                    ),
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
