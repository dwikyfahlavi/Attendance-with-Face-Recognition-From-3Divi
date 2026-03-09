import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../bloc/admin_dashboard_bloc.dart';

class AdminDashboardPage extends StatelessWidget {
  final String name;
  const AdminDashboardPage(this.name, {super.key});

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
        } else if (state is AdminDashboardUploadSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${state.uploadedCount} templates uploaded successfully',
              ),
              backgroundColor: AppColors.successGreen,
            ),
          );
        } else if (state is AdminDashboardUploadError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Upload failed: ${state.message}'),
              backgroundColor: AppColors.errorRed,
            ),
          );
        } else if (state is AdminDashboardUploadPartialFailure) {
          final details = state.errorMessages.isEmpty
              ? ''
              : '\n\nDetails:\n- ${state.errorMessages.join('\n- ')}';
          showDialog<void>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Upload Incomplete'),
              content: Text(
                'Something went wrong. ${state.failedCount} templates did not upload successfully. Do you want to re-upload the rest of it?$details',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('No'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    context.read<AdminDashboardBloc>().add(
                      RetryUploadFaceTemplatesEvent(state.failedTemplates),
                    );
                  },
                  child: const Text('Yes, Retry'),
                ),
              ],
            ),
          );
        } else if (state is AdminDashboardNoTemplates) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No templates to upload'),
              backgroundColor: AppColors.warningOrange,
            ),
          );
        } else if (state is AdminDashboardAttendanceUploadSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.message ?? 'Today\'s attendance uploaded successfully',
              ),
              backgroundColor: AppColors.successGreen,
            ),
          );
        } else if (state is AdminDashboardAttendanceUploadError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Upload failed: ${state.message.replaceAll('Exception: ', '')}',
              ),
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
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/', (route) => false);
              },
            ),
          ],
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
                                  'Welcome back, $name!',
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
                        if (state is AdminDashboardLoaded) {
                          return _buildStatsCards(
                            totalMembers: state.totalMembers,
                            presentToday: state.presentToday,
                            absentToday: state.absentToday,
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ],
                ),
              ),
            ),
            BlocBuilder<AdminDashboardBloc, AdminDashboardState>(
              builder: (context, state) {
                if (state is AdminDashboardLoading ||
                    state is AdminDashboardUploading ||
                    state is AdminDashboardAttendanceUploading) {
                  return Positioned.fill(
                    child: Container(
                      color: Colors.black26,
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuGrid(BuildContext context) {
    final menuItems = [
      // _MenuItem(
      //   icon: Icons.person_add,
      //   title: 'Register Member',
      //   subtitle: 'Add new member',
      //   color: AppColors.successGreen,
      //   onTap: () {
      //     Navigator.of(context).pushNamed('/admin/register');
      //   },
      // ),
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
      _MenuItem(
        icon: Icons.cloud_upload,
        title: 'Upload Templates',
        subtitle: 'Sync face templates',
        color: AppColors.primaryPurple,
        onTap: () {
          context.read<AdminDashboardBloc>().add(UploadFaceTemplatesEvent());
        },
      ),
      _MenuItem(
        icon: Icons.upload_file,
        title: 'Upload Attendance',
        subtitle: 'Upload today\'s attendance',
        color: AppColors.successGreen,
        onTap: () {
          context.read<AdminDashboardBloc>().add(UploadTodaysAttendanceEvent());
        },
      ),
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
