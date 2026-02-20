// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/attendance_list_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../models/absen_model.dart';

class AttendanceHistoryPage extends StatefulWidget {
  const AttendanceHistoryPage({super.key});

  @override
  State<AttendanceHistoryPage> createState() => _AttendanceHistoryPageState();
}

class _AttendanceHistoryPageState extends State<AttendanceHistoryPage> {
  late DateTime _startDate;
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();
    _endDate = DateTime.now();
    _startDate = _endDate.subtract(const Duration(days: 30));
    // Load attendance records with date filter (last 30 days)
    context.read<AttendanceListBloc>().add(
      FilterAttendanceEvent(startDate: _startDate, endDate: _endDate),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance History'),
        elevation: 2,
        backgroundColor: AppColors.primaryPurple,
      ),
      body: Column(
        children: [
          // Date filter
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildDateButton(
                    label: 'From',
                    date: _startDate,
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _startDate,
                        firstDate: DateTime(2024),
                        lastDate: _endDate,
                      );
                      if (picked != null && picked != _startDate) {
                        setState(() => _startDate = picked);
                        // Trigger filter event with new date range
                        context.read<AttendanceListBloc>().add(
                          FilterAttendanceEvent(
                            startDate: picked,
                            endDate: _endDate,
                          ),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDateButton(
                    label: 'To',
                    date: _endDate,
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _endDate,
                        firstDate: _startDate,
                        lastDate: DateTime.now(),
                      );
                      if (picked != null && picked != _endDate) {
                        setState(() => _endDate = picked);
                        // Trigger filter event with new date range
                        context.read<AttendanceListBloc>().add(
                          FilterAttendanceEvent(
                            startDate: _startDate,
                            endDate: picked,
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          // History list
          Expanded(
            child: BlocBuilder<AttendanceListBloc, AttendanceListState>(
              builder: (context, state) {
                if (state is AttendanceListLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is AttendanceListError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: AppColors.errorRed.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          state.message,
                          style: AppTextStyles.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                if (state is AttendanceListLoaded) {
                  if (state.items.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history,
                            size: 64,
                            color: AppColors.textSecondary.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No attendance records',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: state.items.length,
                    itemBuilder: (context, index) {
                      final record = state.items[index];
                      return _buildHistoryCard(record);
                    },
                  );
                }

                return const Center(child: Text('No data'));
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateButton({
    required String label,
    required DateTime date,
    required VoidCallback onPressed,
  }) {
    return Material(
      child: InkWell(
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.primaryPurple, width: 1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('dd MMM yyyy').format(date),
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryCard(AbsenModel record) {
    Color statusColor;
    IconData statusIcon;
    String statusLabel;

    if (record.isLate) {
      statusColor = AppColors.warningOrange;
      statusIcon = Icons.schedule;
      statusLabel = 'Late';
    } else if (record.status == 'OnTime') {
      statusColor = AppColors.successGreen;
      statusIcon = Icons.check_circle;
      statusLabel = 'On Time';
    } else {
      statusColor = AppColors.errorRed;
      statusIcon = Icons.cancel;
      statusLabel = 'Absent';
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(statusIcon, color: statusColor),
        ),
        title: Text(record.nama, style: AppTextStyles.titleSmall),
        subtitle: Text(
          DateFormat('dd MMM yyyy, HH:mm').format(record.jamAbsen),
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            statusLabel,
            style: AppTextStyles.labelSmall.copyWith(color: statusColor),
          ),
        ),
      ),
    );
  }
}
