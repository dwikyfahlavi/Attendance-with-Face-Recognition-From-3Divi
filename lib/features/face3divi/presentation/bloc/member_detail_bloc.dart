import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:typed_data';
import 'package:face_sdk_3divi/face_sdk_3divi.dart';
import '../../data/repository/user_repository.dart';
import '../../data/repository/face_sdk_repository.dart';
import '../../data/models/user_model.dart';
import '../../../../core/constants/face_recognition_config.dart';

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
  final FaceSdkRepository _faceSdkRepository;

  MemberDetailBloc(this._repository, this._faceSdkRepository)
    : super(const MemberDetailInitial()) {
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

      event.user.employeeName = trimmedName.isEmpty
          ? event.user.employeeName
          : trimmedName;
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

  Future<String?> _checkForDuplicateFace(
    Uint8List newImageBytes, {
    String? excludeEmployeeId,
  }) async {
    final session = await _faceSdkRepository.getSession();
    final service = session.service;
    final qaa = session.qaa;
    final templateExtractor = session.templateExtractor;
    final verification = session.verification;

    final allUsers = _repository.getAllUsers();

    AsyncCapturer? capturer;
    try {
      capturer = await service.createAsyncCapturer(
        Config("common_capturer_blf_fda_front.xml"),
      );

      // Extract template from new image
      final List<RawSample> newRss = await capturer.capture(newImageBytes);
      if (newRss.isEmpty) return null; // No face detected

      Context newData = service.createContextFromEncodedImage(newImageBytes);
      newData["objects"].pushBack(newRss[0].toContext());

      await qaa.process(newData);
      await templateExtractor.process(newData);

      final Context newTemplate = service.createContext(
        newData["objects"][0]["face_template"],
      );

      // Check against existing users
      for (final user in allUsers) {
        if (user.employeeId == excludeEmployeeId) {
          continue; // Skip the current user
        }
        if (user.imageBytes != null) {
          final List<RawSample> existingRss = await capturer.capture(
            user.imageBytes!,
          );
          if (existingRss.isEmpty) continue;

          Context existingData = service.createContextFromEncodedImage(
            user.imageBytes!,
          );
          existingData["objects"].pushBack(existingRss[0].toContext());

          await qaa.process(existingData);
          await templateExtractor.process(existingData);

          final Context existingTemplate = service.createContext(
            existingData["objects"][0]["face_template"],
          );

          // Compare templates
          final compareCtx = service.createContext({
            "template1": existingTemplate,
            "template2": newTemplate,
          });
          await verification.process(compareCtx);

          final score = compareCtx["result"]["score"].get_value() ?? 0.0;

          existingRss[0].dispose();
          existingData.dispose();
          existingTemplate.dispose();
          compareCtx.dispose();

          if (score >= FaceRecognitionConfig.minMatchScore) {
            // Using the same threshold
            // Duplicate found
            newRss[0].dispose();
            newData.dispose();
            newTemplate.dispose();
            return user.employeeId;
          }
        }
      }

      // No duplicate found
      newRss[0].dispose();
      newData.dispose();
      newTemplate.dispose();
      return null;
    } catch (e) {
      // If comparison fails, assume no duplicate
      return null;
    } finally {
      await capturer?.dispose();
    }
  }

  Future<void> _onUpdateTemplate(
    UpdateMemberTemplate event,
    Emitter<MemberDetailState> emit,
  ) async {
    try {
      emit(MemberDetailLoading(event.user));

      // Check for duplicate face, excluding the current user
      final duplicateEmployeeId = await _checkForDuplicateFace(
        event.imageBytes,
        excludeEmployeeId: event.user.employeeId,
      );
      if (duplicateEmployeeId != null) {
        emit(
          MemberDetailError(
            event.user,
            'Face already registered for employee ID: $duplicateEmployeeId. Please use a different person.',
          ),
        );
        return;
      }

      event.user.imageBytes = event.imageBytes;
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
