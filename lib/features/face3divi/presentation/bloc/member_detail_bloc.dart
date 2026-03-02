import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:typed_data';
import '../../data/user_repository.dart';
import '../../../../models/user_model.dart';

enum MemberDetailAction { updated, deleted }

// Events
abstract class MemberDetailEvent {}

class InitializeMemberDetail extends MemberDetailEvent {
  final RegisteredUser user;
  InitializeMemberDetail(this.user);
}

class UpdateMemberDetail extends MemberDetailEvent {
  final RegisteredUser user;
  final String name;
  final String? department;
  final bool isAdmin;

  UpdateMemberDetail({
    required this.user,
    required this.name,
    required this.department,
    required this.isAdmin,
  });
}

class DeleteMemberDetail extends MemberDetailEvent {
  final RegisteredUser user;
  DeleteMemberDetail(this.user);
}

class UpdateMemberTemplate extends MemberDetailEvent {
  final RegisteredUser user;
  final Uint8List imageBytes;

  UpdateMemberTemplate({required this.user, required this.imageBytes});
}

// States
abstract class MemberDetailState {
  final RegisteredUser? user;
  const MemberDetailState(this.user);
}

class MemberDetailInitial extends MemberDetailState {
  const MemberDetailInitial() : super(null);
}

class MemberDetailLoading extends MemberDetailState {
  const MemberDetailLoading(super.user);
}

class MemberDetailLoaded extends MemberDetailState {
  const MemberDetailLoaded(RegisteredUser super.user);
}

class MemberDetailActionSuccess extends MemberDetailState {
  final MemberDetailAction action;
  final String message;

  const MemberDetailActionSuccess(super.user, this.action, this.message);
}

class MemberDetailError extends MemberDetailState {
  final String message;
  const MemberDetailError(super.user, this.message);
}

// BLoC
class MemberDetailBloc extends Bloc<MemberDetailEvent, MemberDetailState> {
  final UserRepository _repository;

  MemberDetailBloc(this._repository) : super(const MemberDetailInitial()) {
    on<InitializeMemberDetail>(_onInitialize);
    on<UpdateMemberDetail>(_onUpdate);
    on<DeleteMemberDetail>(_onDelete);
    on<UpdateMemberTemplate>(_onUpdateTemplate);
  }

  Future<void> _onInitialize(
    InitializeMemberDetail event,
    Emitter<MemberDetailState> emit,
  ) async {
    emit(MemberDetailLoaded(event.user));
  }

  Future<void> _onUpdate(
    UpdateMemberDetail event,
    Emitter<MemberDetailState> emit,
  ) async {
    try {
      emit(MemberDetailLoading(event.user));
      final trimmedName = event.name.trim();
      final trimmedDepartment = event.department?.trim();

      event.user.nama = trimmedName.isEmpty ? event.user.nama : trimmedName;
      event.user.department =
          (trimmedDepartment == null || trimmedDepartment.isEmpty)
          ? null
          : trimmedDepartment;
      event.user.isAdmin = event.isAdmin;

      await _repository.updateUser(event.user);

      emit(
        MemberDetailActionSuccess(
          event.user,
          MemberDetailAction.updated,
          'Member updated successfully',
        ),
      );
      emit(MemberDetailLoaded(event.user));
    } catch (e) {
      emit(MemberDetailError(event.user, e.toString()));
    }
  }

  Future<void> _onDelete(
    DeleteMemberDetail event,
    Emitter<MemberDetailState> emit,
  ) async {
    try {
      emit(MemberDetailLoading(event.user));
      await _repository.deleteUser(event.user);
      emit(
        const MemberDetailActionSuccess(
          null,
          MemberDetailAction.deleted,
          'Member deleted successfully',
        ),
      );
    } catch (e) {
      emit(MemberDetailError(event.user, e.toString()));
    }
  }

  Future<void> _onUpdateTemplate(
    UpdateMemberTemplate event,
    Emitter<MemberDetailState> emit,
  ) async {
    try {
      emit(MemberDetailLoading(event.user));
      event.user.imageBytes = event.imageBytes;
      event.user.templateBytes = event.imageBytes;
      event.user.hasTemplate = true;
      await _repository.updateUser(event.user);
      emit(
        MemberDetailActionSuccess(
          event.user,
          MemberDetailAction.updated,
          'Face template updated successfully',
        ),
      );
      emit(MemberDetailLoaded(event.user));
    } catch (e) {
      emit(MemberDetailError(event.user, e.toString()));
    }
  }
}
