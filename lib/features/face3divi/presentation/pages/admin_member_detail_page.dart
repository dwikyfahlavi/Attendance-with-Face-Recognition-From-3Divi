import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'dart:typed_data';
import '../../../../core/theme/app_colors.dart';
import '../bloc/member_detail_bloc.dart';
import 'member_template_capture_page.dart';
import '../../../../models/user_model.dart';

class AdminMemberDetailPage extends StatelessWidget {
  final RegisteredUser user;

  const AdminMemberDetailPage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MemberDetailBloc, MemberDetailState>(
      listener: (context, state) {
        if (state is MemberDetailActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.successGreen,
            ),
          );
          if (state.action == MemberDetailAction.deleted) {
            Navigator.of(context).pop();
          }
        } else if (state is MemberDetailError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.errorRed,
            ),
          );
        }
      },
      builder: (context, state) {
        final displayUser = state.user ?? user;
        final isLoading = state is MemberDetailLoading;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Member Details'),
            elevation: 0,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            bottom: isLoading
                ? const PreferredSize(
                    preferredSize: Size.fromHeight(2),
                    child: LinearProgressIndicator(minHeight: 2),
                  )
                : null,
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                // Profile header
                Container(
                  width: double.infinity,
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 24,
                    horizontal: 20,
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: Icon(
                          Icons.person_outline,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        displayUser.employeeName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                // Details section - Full width card
                Container(
                  color: const Color(0xFFFAFAFA),
                  padding: const EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: 16,
                  ),
                  child: Column(
                    children: [
                      // Main info card
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInfoRow(
                              'Employee ID',
                              displayUser.employeeId,
                            ),
                            const SizedBox(height: 12),
                            _buildInfoRow(
                              'Full Name',
                              displayUser.employeeName,
                            ),
                            if (displayUser.department != null) ...[
                              const SizedBox(height: 12),
                              _buildInfoRow(
                                'Department',
                                displayUser.department!,
                              ),
                            ],
                            const SizedBox(height: 12),
                            _buildInfoRow(
                              'Last Check-in',
                              displayUser.lastAttendanceTime != null
                                  ? DateFormat(
                                      'dd MMM yyyy, HH:mm',
                                    ).format(displayUser.lastAttendanceTime!)
                                  : 'No attendance yet',
                            ),
                            const SizedBox(height: 20),
                            Container(
                              width: double.infinity,
                              height: 1,
                              color: Colors.grey[200],
                            ),
                            const SizedBox(height: 20),
                            _buildStatusInfo(displayUser),
                            const SizedBox(height: 8),
                            _buildTemplateInfo(displayUser),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Action buttons
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                          onPressed: isLoading
                              ? null
                              : () => _captureTemplate(context, displayUser),
                          child: Text(
                            displayUser.imageBytes != null
                                ? 'Update Face Template'
                                : 'Add Face Template',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryPurple,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                          onPressed: isLoading
                              ? null
                              : () => _showEditDialog(context, displayUser),
                          child: const Text(
                            'Edit Member',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.errorRed,
                            side: BorderSide(
                              color: AppColors.errorRed.withOpacity(0.3),
                              width: 1.5,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: isLoading
                              ? null
                              : () => _showDeleteConfirmation(
                                  context,
                                  displayUser,
                                ),
                          child: const Text(
                            'Delete Member',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black54,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
        ),
        // const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildStatusInfo(RegisteredUser user) {
    final isAdmin = user.isAdmin;
    final statusColor = isAdmin
        ? AppColors.warningOrange
        : AppColors.successGreen;
    final statusText = isAdmin ? 'Administrator' : 'Active Member';

    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: statusColor,
            borderRadius: BorderRadius.circular(5),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Account Status',
              style: TextStyle(
                fontSize: 12,
                color: Colors.black54,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              statusText,
              style: TextStyle(
                fontSize: 15,
                color: statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTemplateInfo(RegisteredUser user) {
    final hasTemplate = user.imageBytes != null;
    final color = hasTemplate
        ? AppColors.successGreen
        : AppColors.warningOrange;

    return Row(
      children: [
        Icon(
          hasTemplate ? Icons.verified : Icons.no_accounts,
          color: color,
          size: 16,
        ),
        const SizedBox(width: 8),
        Text(
          hasTemplate ? 'Face template available' : 'Face template not set',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Future<void> _captureTemplate(
    BuildContext context,
    RegisteredUser user,
  ) async {
    final bytes = await Navigator.of(context).push<Uint8List>(
      MaterialPageRoute(builder: (_) => const MemberTemplateCapturePage()),
    );

    if (bytes == null) {
      return;
    }

    if (!context.mounted) {
      return;
    }

    context.read<MemberDetailBloc>().add(
      UpdateMemberTemplate(user: user, imageBytes: bytes),
    );
  }

  void _showEditDialog(BuildContext context, RegisteredUser user) {
    final bloc = context.read<MemberDetailBloc>();
    final nameController = TextEditingController(text: user.employeeName);
    final departmentController = TextEditingController(
      text: user.department ?? '',
    );
    var isAdmin = user.isAdmin;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          title: const Text(
            'Edit Member',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: departmentController,
                  decoration: InputDecoration(
                    labelText: 'Department',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.primaryPurple.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.primaryPurple.withOpacity(0.2),
                    ),
                  ),
                  child: SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    value: isAdmin,
                    onChanged: (value) => setDialogState(() => isAdmin = value),
                    title: const Text(
                      'Admin Access',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    activeColor: AppColors.primaryPurple,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryPurple,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                bloc.add(
                  UpdateMemberDetail(
                    user: user,
                    name: nameController.text,
                    department: departmentController.text,
                    isAdmin: isAdmin,
                  ),
                );
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, RegisteredUser user) {
    final bloc = context.read<MemberDetailBloc>();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text(
          'Delete Member',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Text(
          'Are you sure you want to delete ${user.employeeName}? This action cannot be undone.',
          style: const TextStyle(fontSize: 15, color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.of(context).pop();
              bloc.add(DeleteMemberDetail(user));
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
