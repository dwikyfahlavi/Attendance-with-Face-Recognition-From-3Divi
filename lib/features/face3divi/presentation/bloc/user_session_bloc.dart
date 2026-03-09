import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fr3divi/features/face3divi/data/models/user_model.dart';

// Events
abstract class UserSessionEvent {}

class UserLoggedInEvent extends UserSessionEvent {
  final RegisteredUser user;
  UserLoggedInEvent(this.user);
}

class UserLoggedOutEvent extends UserSessionEvent {}

// States
abstract class UserSessionState {
  const UserSessionState();
}

class UserSessionInitial extends UserSessionState {
  const UserSessionInitial();
}

class UserSessionActive extends UserSessionState {
  final RegisteredUser user;
  const UserSessionActive(this.user);
}

class UserSessionInactive extends UserSessionState {
  const UserSessionInactive();
}

// BLoC
class UserSessionBloc extends Bloc<UserSessionEvent, UserSessionState> {
  UserSessionBloc() : super(const UserSessionInitial()) {
    on<UserLoggedInEvent>(_onUserLoggedIn);
    on<UserLoggedOutEvent>(_onUserLoggedOut);
  }

  Future<void> _onUserLoggedIn(
    UserLoggedInEvent event,
    Emitter<UserSessionState> emit,
  ) async {
    emit(UserSessionActive(event.user));
  }

  Future<void> _onUserLoggedOut(
    UserLoggedOutEvent event,
    Emitter<UserSessionState> emit,
  ) async {
    emit(const UserSessionInactive());
  }
}
