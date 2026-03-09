import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repository/user_repository.dart';
import '../../data/models/user_model.dart';

// Events
abstract class UserListEvent {}

class LoadUsersEvent extends UserListEvent {}

class RefreshUsersEvent extends UserListEvent {}

// States
abstract class UserListState {
  const UserListState();
}

class UserListInitial extends UserListState {
  const UserListInitial();
}

class UserListLoading extends UserListState {
  const UserListLoading();
}

class UserListLoaded extends UserListState {
  final List<RegisteredUser> users;
  const UserListLoaded(this.users);
}

class UserListError extends UserListState {
  final String message;
  const UserListError(this.message);
}

// BLoC
class UserListBloc extends Bloc<UserListEvent, UserListState> {
  final UserRepository _repository;

  UserListBloc(this._repository) : super(const UserListInitial()) {
    on<LoadUsersEvent>(_onLoadUsers);
    on<RefreshUsersEvent>(_onRefreshUsers);
  }

  Future<void> _onLoadUsers(
    LoadUsersEvent event,
    Emitter<UserListState> emit,
  ) async {
    try {
      emit(const UserListLoading());

      // Subscribe to user changes via stream
      await emit.forEach(
        _repository.watchUsers(),
        onData: (List<RegisteredUser> users) {
          return UserListLoaded(users);
        },
        onError: (error, stackTrace) {
          return UserListError(error.toString());
        },
      );
    } catch (e) {
      emit(UserListError(e.toString()));
    }
  }

  Future<void> _onRefreshUsers(
    RefreshUsersEvent event,
    Emitter<UserListState> emit,
  ) async {
    try {
      emit(const UserListLoading());
      final users = _repository.getAllUsers();
      emit(UserListLoaded(users));
    } catch (e) {
      emit(UserListError(e.toString()));
    }
  }
}
