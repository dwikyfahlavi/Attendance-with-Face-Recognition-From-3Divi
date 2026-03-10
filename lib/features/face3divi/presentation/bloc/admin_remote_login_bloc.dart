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
        final allAbsen = await serviceLocator.absenRepository.getAllAbsen();

        // Remove local records that have serverId (synced ones) to replace with API data
        for (var item in allAbsen) {
          if (item.serverId != null || item.isUploaded) {
            await item.delete();
          }
          // Local data without serverId is left untouched
        }

        // Add data from API for history attendance
        for (var item in history) {
          await serviceLocator.absenRepository.addAbsen(item);
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
