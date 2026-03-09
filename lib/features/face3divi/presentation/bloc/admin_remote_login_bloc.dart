import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fr3divi/features/face3divi/data/data_source/remote_auth_data_source.dart';
import 'package:fr3divi/features/face3divi/data/repository/remote_auth_repository.dart';

import '../../../../core/di/service_locator.dart';

// Events
abstract class AdminRemoteLoginEvent {}

class LoginRequested extends AdminRemoteLoginEvent {
  final String username;
  final String password;

  LoginRequested(this.username, this.password);
}

// States
abstract class AdminRemoteLoginState {}

class AdminRemoteLoginInitial extends AdminRemoteLoginState {}

class AdminRemoteLoginLoading extends AdminRemoteLoginState {}

class AdminRemoteLoginSuccess extends AdminRemoteLoginState {
  final String user;

  AdminRemoteLoginSuccess(this.user);
}

class AdminRemoteLoginError extends AdminRemoteLoginState {
  final String message;

  AdminRemoteLoginError(this.message);
}

// BLoC
class AdminRemoteLoginBloc
    extends Bloc<AdminRemoteLoginEvent, AdminRemoteLoginState> {
  final RemoteAuthRepository _remoteAuthRepository;
  AdminRemoteLoginBloc(this._remoteAuthRepository)
    : super(AdminRemoteLoginInitial()) {
    on<LoginRequested>(_onLoginRequested);
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AdminRemoteLoginState> emit,
  ) async {
    emit(AdminRemoteLoginLoading());

    try {
      // Perform login and sync user
      final user = await _remoteAuthRepository.loginAndSyncUser(
        username: event.username.trim(),
        password: event.password,
      );

      // Fetch and sync attendance history, checking for attendance/absent differences
      try {
        final history = await serviceLocator.absenRepository
            .fetchAttendanceHistory();

        for (final item in history) {
          final allAbsen = await serviceLocator.absenRepository.getAllAbsen();
          final existingList = allAbsen.where(
            (local) => local.serverId == item.serverId,
          );

          if (existingList.isNotEmpty) {
            final existing = existingList.first;
            // Update existing record
            existing.employeeId = item.employeeId;
            existing.nama = item.nama;
            existing.jamAbsen = item.jamAbsen;
            existing.type = item.type;
            existing.isUploaded = item.isUploaded;
            existing.createdDate = item.createdDate;
            existing.updatedDate = item.updatedDate;

            await existing.save();
          } else {
            // Add new record with absence check

            await serviceLocator.absenRepository.addAbsen(item);
          }
        }
      } catch (e) {
        // Log error but continue (e.g., print('Failed to sync attendance history: $e'))
      }

      emit(AdminRemoteLoginSuccess(user));
    } on RemoteAuthException catch (e) {
      emit(AdminRemoteLoginError(e.message));
    } catch (_) {
      emit(AdminRemoteLoginError('Login failed. Please try again.'));
    }
  }
}
