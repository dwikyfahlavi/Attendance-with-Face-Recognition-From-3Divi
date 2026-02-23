import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../bloc/admin_dashboard_bloc.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AdminDashboardBloc, AdminDashboardState>(
      listener: (context, state) {
        if (state is AdminDashboardError) {
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
          title: const Text('Dashboard'),
          elevation: 0,
          backgroundColor: AppColors.backgroundWhite,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                context.read<AdminDashboardBloc>().add(RefreshDashboardEvent());
              },
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                // Logout and return to home
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/', (route) => false);
              },
            ),
          ],
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
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundWhite,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: AppColors.primaryPurple.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.verified_user,
                          color: AppColors.primaryPurple,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome back',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Admin Dashboard',
                              style: AppTextStyles.headlineMedium.copyWith(
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text('Quick Actions', style: AppTextStyles.titleLarge),
                const SizedBox(height: 14),
                _buildMenuGrid(context),
                const SizedBox(height: 28),
                Text('Overview', style: AppTextStyles.titleLarge),
                const SizedBox(height: 14),
                BlocBuilder<AdminDashboardBloc, AdminDashboardState>(
                  builder: (context, state) {
                    if (state is AdminDashboardLoading) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (state is AdminDashboardLoaded) {
                      return _buildStatsCards(
                        totalMembers: state.totalMembers,
                        presentToday: state.presentToday,
                        absentToday: state.absentToday,
                      );
                    } else {
                      return const SizedBox.shrink();
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget _buildMenuGrid(BuildContext context) {
    final menuItems = [
      _MenuItem(
        icon: Icons.person_add,
        title: 'Register Member',
        subtitle: 'Add new member',
        color: AppColors.successGreen,
        onTap: () {
          Navigator.of(context).pushNamed('/admin/register');
        },
      ),
      _MenuItem(
        icon: Icons.people,
        title: 'Members List',
        subtitle: 'View all members',
        color: AppColors.secondary,
        onTap: () {
          Navigator.of(context).pushNamed('/admin/members');
        },
      ),
      _MenuItem(
        icon: Icons.calendar_month,
        title: 'Attendance',
        subtitle: 'View attendance records',
        color: AppColors.warningOrange,
        onTap: () {
          Navigator.of(context).pushNamed('/admin/attendance');
        },
      ),
      // _MenuItem(
      //   icon: Icons.login,
      //   title: 'Login API',
      //   subtitle: 'Sync user from server',
      //   color: AppColors.primaryPurple,
      //   onTap: () {
      //     Navigator.of(context).pushNamed('/admin/login-api');
      //   },
      // ),
      _MenuItem(
        icon: Icons.settings,
        title: 'Settings',
        subtitle: 'Configure app settings',
        color: AppColors.primaryPurple,
        onTap: () {
          Navigator.of(context).pushNamed('/admin/settings');
        },
      ),
    ];

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.95,
      ),
      itemCount: menuItems.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) => _MenuCard(item: menuItems[index]),
    );
  }

  static Widget _buildStatsCards({
    required int totalMembers,
    required int presentToday,
    required int absentToday,
  }) {
    return Column(
      children: [
        _buildStatCard(
          label: 'Total Members',
          value: totalMembers.toString(),
          icon: Icons.people,
          color: AppColors.secondary,
        ),
        const SizedBox(height: 12),
        _buildStatCard(
          label: 'Present Today',
          value: presentToday.toString(),
          icon: Icons.check_circle,
          color: AppColors.successGreen,
        ),
        const SizedBox(height: 12),
        _buildStatCard(
          label: 'Absent Today',
          value: absentToday.toString(),
          icon: Icons.cancel,
          color: AppColors.errorRed,
        ),
      ],
    );
  }

  static Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: AppTextStyles.headlineMedium.copyWith(color: color),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
}

class _MenuCard extends StatelessWidget {
  final _MenuItem item;

  const _MenuCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: AppColors.backgroundWhite,
            border: Border.all(color: AppColors.borderLight),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: item.color.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, color: item.color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                item.title,
                style: AppTextStyles.titleSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                item.subtitle,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
