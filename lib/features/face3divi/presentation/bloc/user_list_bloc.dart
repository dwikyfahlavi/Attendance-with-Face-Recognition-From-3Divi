import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repository/user_repository.dart';
import '../../data/models/user_model.dart';

// Events
abstract class UserListEvent {}

class LoadUsersEvent extends UserListEvent {}

class RefreshUsersEvent extends UserListEvent {}

class FilterUsersByGangEvent extends UserListEvent {
  final String? selectedGang;
  FilterUsersByGangEvent(this.selectedGang);
}

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
  final List<String> availableGangs;
  final String? selectedGang;

  const UserListLoaded(
    this.users, {
    this.availableGangs = const [],
    this.selectedGang,
  });
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
    on<FilterUsersByGangEvent>(_onFilterUsersByGang);
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
          final gangs = _extractUniqueGangs(users);
          print('Loaded ${users.length} users with gangs: $gangs');
          return UserListLoaded(users, availableGangs: gangs);
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
      final gangs = _extractUniqueGangs(users);
      emit(UserListLoaded(users, availableGangs: gangs));
    } catch (e) {
      emit(UserListError(e.toString()));
    }
  }

  Future<void> _onFilterUsersByGang(
    FilterUsersByGangEvent event,
    Emitter<UserListState> emit,
  ) async {
    try {
      if (state is UserListLoaded) {
        final currentState = state as UserListLoaded;
        emit(
          UserListLoaded(
            currentState.users,
            availableGangs: currentState.availableGangs,
            selectedGang: event.selectedGang,
          ),
        );
      }
    } catch (e) {
      emit(UserListError(e.toString()));
    }
  }

  List<String> _extractUniqueGangs(List<RegisteredUser> users) {
    final gangs = <String>{};
    for (final user in users) {
      if (user.employeeGangAllotmentCode != null &&
          user.employeeGangAllotmentCode!.isNotEmpty) {
        gangs.add(user.employeeGangAllotmentCode!);
      }
    }
    return gangs.toList()..sort();
  }
}
