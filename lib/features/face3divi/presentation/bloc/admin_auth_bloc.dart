import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fr3divi/features/face3divi/data/user_repository.dart';
import 'package:fr3divi/features/face3divi/data/admin_pin_repository.dart';
import 'package:fr3divi/models/user_model.dart';

// Events
abstract class AdminAuthEvent {}

class AuthenticateWithPINEvent extends AdminAuthEvent {
  final String pin;
  AuthenticateWithPINEvent(this.pin);
}

class AuthenticateWithFaceEvent extends AdminAuthEvent {
  final String userEmployeeId;
  AuthenticateWithFaceEvent(this.userEmployeeId);
}

class LogoutAdminEvent extends AdminAuthEvent {}

// States
abstract class AdminAuthState {
  const AdminAuthState();
}

class AdminAuthInitial extends AdminAuthState {
  const AdminAuthInitial();
}

class AdminAuthLoading extends AdminAuthState {
  const AdminAuthLoading();
}

class AdminAuthSuccess extends AdminAuthState {
  final RegisteredUser? user;
  const AdminAuthSuccess({this.user});
}

class AdminAuthFailed extends AdminAuthState {
  final String reason;
  const AdminAuthFailed(this.reason);
}

class AdminLoggedOut extends AdminAuthState {
  const AdminLoggedOut();
}

// BLoC
class AdminAuthBloc extends Bloc<AdminAuthEvent, AdminAuthState> {
  final UserRepository _userRepository;
  final AdminPinRepository _adminPinRepository;

  AdminAuthBloc(this._userRepository, this._adminPinRepository)
    : super(const AdminAuthInitial()) {
    on<AuthenticateWithPINEvent>(_onAuthenticateWithPIN);
    on<AuthenticateWithFaceEvent>(_onAuthenticateWithFace);
    on<LogoutAdminEvent>(_onLogout);
  }

  Future<void> _onAuthenticateWithPIN(
    AuthenticateWithPINEvent event,
    Emitter<AdminAuthState> emit,
  ) async {
    try {
      emit(const AdminAuthLoading());

      // Verify PIN using AdminPinRepository
      final isValidPin = await _adminPinRepository.verifyPIN(event.pin);

      if (isValidPin) {
        emit(const AdminAuthSuccess());
      } else {
        emit(const AdminAuthFailed('Invalid PIN. Please try again.'));
      }
    } catch (e) {
      emit(AdminAuthFailed(e.toString()));
    }
  }

  Future<void> _onAuthenticateWithFace(
    AuthenticateWithFaceEvent event,
    Emitter<AdminAuthState> emit,
  ) async {
    try {
      emit(const AdminAuthLoading());

      // Verify user exists and has admin role
      final user = _userRepository.getUserByEmployeeId(event.userEmployeeId);

      if (user == null) {
        emit(const AdminAuthFailed('User not found'));
        return;
      }

      // Check if user has admin role
      if (user.isAdmin) {
        emit(AdminAuthSuccess(user: user));
      } else {
        emit(const AdminAuthFailed('User does not have admin privileges'));
      }
    } catch (e) {
      emit(AdminAuthFailed(e.toString()));
    }
  }

  Future<void> _onLogout(
    LogoutAdminEvent event,
    Emitter<AdminAuthState> emit,
  ) async {
    emit(const AdminLoggedOut());
  }
}
