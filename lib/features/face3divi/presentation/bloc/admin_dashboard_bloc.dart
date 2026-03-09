import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:convert';
import '../../data/repository/user_repository.dart';
import '../../data/repository/absen_repository.dart';
import '../../data/repository/remote_auth_repository.dart';
import '../../data/data_source/remote_auth_data_source.dart';

// Events
abstract class AdminDashboardEvent {}

class LoadDashboardEvent extends AdminDashboardEvent {}

class RefreshDashboardEvent extends AdminDashboardEvent {}

class UploadFaceTemplatesEvent extends AdminDashboardEvent {}

class RetryUploadFaceTemplatesEvent extends AdminDashboardEvent {
  final List<Map<String, String>> templates;
  RetryUploadFaceTemplatesEvent(this.templates);
}

class UploadTodaysAttendanceEvent extends AdminDashboardEvent {}

// States
abstract class AdminDashboardState {
  const AdminDashboardState();
}

class AdminDashboardInitial extends AdminDashboardState {
  const AdminDashboardInitial();
}

class AdminDashboardLoading extends AdminDashboardState {
  const AdminDashboardLoading();
}

class AdminDashboardLoaded extends AdminDashboardState {
  final int totalMembers;
  final int presentToday;
  final int absentToday;

  const AdminDashboardLoaded({
    required this.totalMembers,
    required this.presentToday,
    required this.absentToday,
  });
}

class AdminDashboardError extends AdminDashboardState {
  final String message;
  const AdminDashboardError(this.message);
}

class AdminDashboardUploading extends AdminDashboardState {
  const AdminDashboardUploading();
}

class AdminDashboardUploadSuccess extends AdminDashboardState {
  final int uploadedCount;
  const AdminDashboardUploadSuccess(this.uploadedCount);
}

class AdminDashboardUploadError extends AdminDashboardState {
  final String message;
  const AdminDashboardUploadError(this.message);
}

class AdminDashboardNoTemplates extends AdminDashboardState {
  const AdminDashboardNoTemplates();
}

class AdminDashboardUploadPartialFailure extends AdminDashboardState {
  final int failedCount;
  final List<Map<String, String>> failedTemplates;
  final List<String> errorMessages;
  const AdminDashboardUploadPartialFailure({
    required this.failedCount,
    required this.failedTemplates,
    required this.errorMessages,
  });
}

class AdminDashboardAttendanceUploading extends AdminDashboardState {
  const AdminDashboardAttendanceUploading();
}

class AdminDashboardAttendanceUploadSuccess extends AdminDashboardState {
  final String? message;
  const AdminDashboardAttendanceUploadSuccess([this.message]);
}

class AdminDashboardAttendanceUploadError extends AdminDashboardState {
  final String message;
  const AdminDashboardAttendanceUploadError(this.message);
}

// BLoC
class AdminDashboardBloc
    extends Bloc<AdminDashboardEvent, AdminDashboardState> {
  final UserRepository _userRepository;
  final AbsenRepository _absenRepository;
  final RemoteAuthRepository _remoteAuthRepository;

  AdminDashboardBloc(
    this._userRepository,
    this._absenRepository,
    this._remoteAuthRepository,
  ) : super(const AdminDashboardInitial()) {
    on<LoadDashboardEvent>(_onLoadDashboard);
    on<RefreshDashboardEvent>(_onRefreshDashboard);
    on<UploadFaceTemplatesEvent>(_onUploadFaceTemplates);
    on<RetryUploadFaceTemplatesEvent>(_onRetryUploadFaceTemplates);
    on<UploadTodaysAttendanceEvent>(_onUploadTodaysAttendance);
  }

  Future<void> _onLoadDashboard(
    LoadDashboardEvent event,
    Emitter<AdminDashboardState> emit,
  ) async {
    try {
      emit(const AdminDashboardLoading());
      await _loadAndEmitDashboardData(emit);
    } catch (e) {
      emit(AdminDashboardError(e.toString()));
    }
  }

  Future<void> _onRefreshDashboard(
    RefreshDashboardEvent event,
    Emitter<AdminDashboardState> emit,
  ) async {
    try {
      await _loadAndEmitDashboardData(emit);
    } catch (e) {
      emit(AdminDashboardError(e.toString()));
    }
  }

  Future<void> _onUploadFaceTemplates(
    UploadFaceTemplatesEvent event,
    Emitter<AdminDashboardState> emit,
  ) async {
    try {
      emit(const AdminDashboardUploading());

      final users = _userRepository.getAllUsers();
      final usersWithTemplates = users
          .where((user) => user.imageBytes != null)
          .toList();

      if (usersWithTemplates.isEmpty) {
        emit(const AdminDashboardNoTemplates());
        await _loadAndEmitDashboardData(emit);
        return;
      }

      final templates = usersWithTemplates
          .map(
            (user) => <String, String>{
              'employee_id': user.employeeId,
              'employee_face_template': user.imageBytes != null
                  ? base64Encode(user.imageBytes!)
                  : '',
            },
          )
          .toList();

      await _uploadTemplatesAndEmitResult(emit, templates);
    } catch (e) {
      emit(AdminDashboardUploadError(e.toString()));
    }
  }

  Future<void> _onRetryUploadFaceTemplates(
    RetryUploadFaceTemplatesEvent event,
    Emitter<AdminDashboardState> emit,
  ) async {
    try {
      if (event.templates.isEmpty) {
        emit(const AdminDashboardNoTemplates());
        await _loadAndEmitDashboardData(emit);
        return;
      }
      emit(const AdminDashboardUploading());
      await _uploadTemplatesAndEmitResult(emit, event.templates);
    } catch (e) {
      emit(AdminDashboardUploadError(e.toString()));
      await _loadAndEmitDashboardData(emit);
    }
  }

  Future<void> _uploadTemplatesAndEmitResult(
    Emitter<AdminDashboardState> emit,
    List<Map<String, String>> templates,
  ) async {
    final result = await _remoteAuthRepository.uploadFaceTemplates(templates);

    if (!result.status) {
      emit(const AdminDashboardUploadError('Upload failed. Please try again.'));
      await _loadAndEmitDashboardData(emit);
      return;
    }

    if (result.totalError > 0) {
      final failedTemplates = _mapFailedTemplates(result, templates);
      final errorMessages = _mapErrorMessages(result);
      emit(
        AdminDashboardUploadPartialFailure(
          failedCount: result.totalError,
          failedTemplates: failedTemplates,
          errorMessages: errorMessages,
        ),
      );
      await _loadAndEmitDashboardData(emit);
      return;
    }

    emit(AdminDashboardUploadSuccess(result.totalSuccess));
    await _loadAndEmitDashboardData(emit);
  }

  List<Map<String, String>> _mapFailedTemplates(
    UploadFaceTemplatesResult result,
    List<Map<String, String>> originalTemplates,
  ) {
    final failed = <Map<String, String>>[];

    for (final apiError in result.errorData) {
      Map<String, String>? candidate;

      if (apiError.index != null &&
          apiError.index! >= 0 &&
          apiError.index! < originalTemplates.length) {
        candidate = originalTemplates[apiError.index!];
      }

      if (candidate == null && apiError.employeeId != null) {
        for (final item in originalTemplates) {
          if (item['employee_id'] == apiError.employeeId) {
            candidate = item;
            break;
          }
        }
      }

      if (candidate != null && !failed.contains(candidate)) {
        failed.add(candidate);
      }
    }

    if (failed.isEmpty && result.totalError > 0) {
      return originalTemplates;
    }

    return failed;
  }

  List<String> _mapErrorMessages(UploadFaceTemplatesResult result) {
    final messages = <String>[];
    for (final apiError in result.errorData) {
      final text = apiError.message.trim();
      if (text.isNotEmpty && !messages.contains(text)) {
        messages.add(text);
      }
      if (messages.length >= 2) {
        break;
      }
    }
    return messages;
  }

  Future<void> _loadAndEmitDashboardData(
    Emitter<AdminDashboardState> emit,
  ) async {
    // Get total members (excluding admins)
    final users = _userRepository.getAllUsers();
    final totalMembers = users.where((user) => !user.isAdmin).length;

    // Get today's date (without time)
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayEnd = DateTime(today.year, today.month, today.day, 23, 59, 59);

    // Get attendance records for today
    final allAttendance = await _absenRepository.getAllAttendance();
    final todayAttendance = allAttendance
        .where(
          (record) =>
              record.jamAbsen.isAfter(todayStart) &&
              record.jamAbsen.isBefore(todayEnd),
        )
        .toList();

    // Count unique users who attended today
    final uniqueEmployeeIdsPresent = <String>{};
    for (var record in todayAttendance) {
      uniqueEmployeeIdsPresent.add(record.employeeId);
    }
    final presentToday = uniqueEmployeeIdsPresent.length;

    // Calculate absent
    final absentToday = totalMembers - presentToday;

    emit(
      AdminDashboardLoaded(
        totalMembers: totalMembers,
        presentToday: presentToday,
        absentToday: absentToday,
      ),
    );
  }

  Future<void> _onUploadTodaysAttendance(
    UploadTodaysAttendanceEvent event,
    Emitter<AdminDashboardState> emit,
  ) async {
    emit(const AdminDashboardAttendanceUploading());
    try {
      final message = await _absenRepository.uploadTodaysAttendance();
      emit(AdminDashboardAttendanceUploadSuccess(message));
    } catch (e) {
      emit(AdminDashboardAttendanceUploadError(e.toString()));
    }
  }
}
