import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fr3divi/features/face3divi/data/absen_repository.dart';
import 'package:fr3divi/features/face3divi/data/user_repository.dart';
import 'package:fr3divi/features/face3divi/data/face_verification_service.dart';
import 'package:fr3divi/features/face3divi/data/settings_repository.dart';
import 'package:fr3divi/models/absen_model.dart';
import 'package:fr3divi/models/user_model.dart';

// Events
abstract class AttendanceScanEvent {}

class RecordAttendanceEvent extends AttendanceScanEvent {
  final RegisteredUser user;
  final DateTime attendanceTime;

  RecordAttendanceEvent(this.user, this.attendanceTime);
}

class MarkAttendanceEvent extends AttendanceScanEvent {
  final String userEmployeeId;
  final String userName;
  final Uint8List? capturedImageBytes;

  MarkAttendanceEvent({
    required this.userEmployeeId,
    required this.userName,
    this.capturedImageBytes,
  });
}

class VerifyFaceEvent extends AttendanceScanEvent {
  final String userEmployeeId;
  final Uint8List imageBytes;

  VerifyFaceEvent({required this.userEmployeeId, required this.imageBytes});
}

class CheckCooldownEvent extends AttendanceScanEvent {
  final String userEmployeeId;
  CheckCooldownEvent(this.userEmployeeId);
}

class ResetScanEvent extends AttendanceScanEvent {}

// States
abstract class AttendanceScanState {
  const AttendanceScanState();
}

class AttendanceScanInitial extends AttendanceScanState {
  const AttendanceScanInitial();
}

class CooldownActive extends AttendanceScanState {
  final int secondsRemaining;
  const CooldownActive(this.secondsRemaining);
}

class AttendanceMarking extends AttendanceScanState {
  const AttendanceMarking();
}

class AttendanceScanSuccess extends AttendanceScanState {
  final RegisteredUser user;
  final AbsenModel attendance;
  final bool isLate;

  const AttendanceScanSuccess({
    required this.user,
    required this.attendance,
    required this.isLate,
  });
}

class AttendanceMarked extends AttendanceScanState {
  final AbsenModel attendance;
  final bool isLate;
  const AttendanceMarked({required this.attendance, required this.isLate});
}

class AttendanceScanError extends AttendanceScanState {
  final String message;
  const AttendanceScanError(this.message);
}

class AttendanceError extends AttendanceScanState {
  final String message;
  const AttendanceError(this.message);
}

// BLoC
class AttendanceScanBloc
    extends Bloc<AttendanceScanEvent, AttendanceScanState> {
  final AbsenRepository _absenRepository;
  final UserRepository _userRepository;
  final FaceVerificationService? _faceVerificationService;
  final SettingsRepository _settingsRepository;
  final int cooldownSeconds = 60;

  AttendanceScanBloc({
    required AbsenRepository absenRepository,
    required UserRepository userRepository,
    required SettingsRepository settingsRepository,
    FaceVerificationService? faceVerificationService,
  }) : _absenRepository = absenRepository,
       _userRepository = userRepository,
       _faceVerificationService = faceVerificationService,
       _settingsRepository = settingsRepository,
       super(const AttendanceScanInitial()) {
    on<RecordAttendanceEvent>(_onRecordAttendance);
    on<MarkAttendanceEvent>(_onMarkAttendance);
    on<VerifyFaceEvent>(_onVerifyFace);
    on<CheckCooldownEvent>(_onCheckCooldown);
    on<ResetScanEvent>(_onReset);
  }

  Future<void> _onRecordAttendance(
    RecordAttendanceEvent event,
    Emitter<AttendanceScanState> emit,
  ) async {
    try {
      emit(const AttendanceMarking());

      final now = event.attendanceTime;
      final user = event.user;

      // Check if user has marked attendance recently
      final lastAttendance = await _absenRepository.getLastAttendanceForUser(
        user.employeeId,
      );

      if (lastAttendance != null) {
        final timeSinceLastAttendance = now.difference(lastAttendance.jamAbsen);
        if (timeSinceLastAttendance.inSeconds < cooldownSeconds) {
          final secondsRemaining =
              cooldownSeconds - timeSinceLastAttendance.inSeconds;
          emit(CooldownActive(secondsRemaining));
          return;
        }
      }

      // Check if late
      final isLate = await _isLateAttendance(now);

      // Create attendance record
      final absen = AbsenModel(
        employeeId: user.employeeId,
        nama: user.employeeName,
        jamAbsen: now,
        isLate: isLate,
        status: isLate ? 'Late' : 'OnTime',
      );

      // Save attendance
      await _absenRepository.addAttendance(absen);

      // Update user's lastAttendanceTime
      user.lastAttendanceTime = now;
      await _userRepository.addOrUpdateUser(user);

      emit(
        AttendanceScanSuccess(user: user, attendance: absen, isLate: isLate),
      );
    } catch (e) {
      emit(AttendanceScanError(e.toString()));
    }
  }

  Future<void> _onMarkAttendance(
    MarkAttendanceEvent event,
    Emitter<AttendanceScanState> emit,
  ) async {
    try {
      emit(const AttendanceMarking());

      // If face verification service available and image provided, verify face first
      if (_faceVerificationService != null &&
          event.capturedImageBytes != null) {
        // Verify face before marking attendance
        final user = _userRepository.getUserByEmployeeId(event.userEmployeeId);
        if (user == null) {
          emit(const AttendanceScanError('User not found'));
          return;
        }

        // Validate image quality and liveness
        final qualityResult = await _faceVerificationService
            .validateImageQualityAndLiveness(event.capturedImageBytes!);

        if (!qualityResult['valid']) {
          emit(
            AttendanceScanError(
              'Image validation failed: ${qualityResult['liveness_verdict']}',
            ),
          );
          return;
        }
      }

      // Check if user has marked attendance recently
      final lastAttendance = await _absenRepository.getLastAttendanceForUser(
        event.userEmployeeId,
      );

      if (lastAttendance != null) {
        final timeSinceLastAttendance = DateTime.now().difference(
          lastAttendance.jamAbsen,
        );
        if (timeSinceLastAttendance.inSeconds < cooldownSeconds) {
          final secondsRemaining =
              cooldownSeconds - timeSinceLastAttendance.inSeconds;
          emit(CooldownActive(secondsRemaining));
          return;
        }
      }

      // Mark new attendance
      final newAttendance = AbsenModel(
        employeeId: event.userEmployeeId,
        nama: event.userName,
        jamAbsen: DateTime.now(),
      );

      // Check if late (compare with settings)
      final isLate = await _isLateAttendance(newAttendance.jamAbsen);
      newAttendance.isLate = isLate;

      await _absenRepository.addAttendance(newAttendance);

      emit(AttendanceMarked(attendance: newAttendance, isLate: isLate));
    } catch (e) {
      emit(AttendanceScanError(e.toString()));
    }
  }

  Future<void> _onVerifyFace(
    VerifyFaceEvent event,
    Emitter<AttendanceScanState> emit,
  ) async {
    try {
      emit(const AttendanceMarking());

      if (_faceVerificationService == null) {
        emit(
          const AttendanceScanError('Face verification service not available'),
        );
        return;
      }

      // Validate image quality and liveness
      final qualityResult = await _faceVerificationService
          .validateImageQualityAndLiveness(event.imageBytes);

      if (!qualityResult['valid']) {
        emit(
          AttendanceScanError(
            'Face verification failed: ${qualityResult['liveness_verdict']}',
          ),
        );
        return;
      }

      // If validation passes, proceed with attendance marking
      emit(const AttendanceScanInitial());
    } catch (e) {
      emit(AttendanceScanError('Face verification error: ${e.toString()}'));
    }
  }

  Future<void> _onCheckCooldown(
    CheckCooldownEvent event,
    Emitter<AttendanceScanState> emit,
  ) async {
    try {
      final lastAttendance = await _absenRepository.getLastAttendanceForUser(
        event.userEmployeeId,
      );

      if (lastAttendance != null) {
        final timeSinceLastAttendance = DateTime.now().difference(
          lastAttendance.jamAbsen,
        );
        if (timeSinceLastAttendance.inSeconds < cooldownSeconds) {
          final secondsRemaining =
              cooldownSeconds - timeSinceLastAttendance.inSeconds;
          emit(CooldownActive(secondsRemaining));
          return;
        }
      }

      emit(const AttendanceScanInitial());
    } catch (e) {
      emit(AttendanceScanError(e.toString()));
    }
  }

  Future<void> _onReset(
    ResetScanEvent event,
    Emitter<AttendanceScanState> emit,
  ) async {
    emit(const AttendanceScanInitial());
  }

  Future<bool> _isLateAttendance(DateTime attendanceTime) async {
    try {
      // Get late hour from settings using settings repository
      return await _settingsRepository.isLateTime(attendanceTime);
    } catch (e) {
      // Default to 9:00 AM if error
      return attendanceTime.hour > 9 ||
          (attendanceTime.hour == 9 && attendanceTime.minute > 0);
    }
  }
}
