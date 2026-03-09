import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fr3divi/features/face3divi/data/repository/absen_repository.dart';
import 'package:fr3divi/features/face3divi/data/repository/user_repository.dart';
import 'package:fr3divi/features/face3divi/data/face_verification_service.dart';
import 'package:fr3divi/features/face3divi/data/repository/settings_repository.dart';
import 'package:fr3divi/features/face3divi/data/models/absen_model.dart';
import 'package:fr3divi/features/face3divi/data/models/user_model.dart';

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
  final String type;

  const AttendanceScanSuccess({
    required this.user,
    required this.attendance,
    required this.type,
  });
}

class AttendanceMarked extends AttendanceScanState {
  final AbsenModel attendance;
  final bool isLate;
  final String type;
  const AttendanceMarked({
    required this.attendance,
    required this.isLate,
    required this.type,
  });
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

      // Get settings for check-out time
      final settings = await _settingsRepository.getSettings();
      final checkOutTime = DateTime(
        now.year,
        now.month,
        now.day,
        settings.checkOutHour,
        settings.checkOutMinute,
      );

      // Determine type: CheckIn if before check-out, else CheckOut
      final type = now.isBefore(checkOutTime) ? 'CheckIn' : 'CheckOut';

      // Check for existing attendance of the same type today
      final todaysAbsen = await _absenRepository.getTodaysAbsen();
      final existingRecords = todaysAbsen.where(
        (a) => a.employeeId == user.employeeId && a.type == type,
      );
      final existing = existingRecords.isNotEmpty
          ? existingRecords.first
          : null;

      AbsenModel absen;

      if (existing != null) {
        // Update the existing record with new time
        existing.jamAbsen = now;
        existing.updatedDate = now;
        await existing.save();
        absen = existing;
      } else {
        // Create new attendance record
        absen = AbsenModel(
          employeeId: user.employeeId,
          nama: user.employeeName,
          jamAbsen: now,
          type: type,
          createdDate: now,
        );

        // Save attendance
        await _absenRepository.addAttendance(absen);
      }

      // Update user's lastAttendanceTime
      user.lastAttendanceTime = now;
      await _userRepository.addOrUpdateUser(user);

      emit(AttendanceScanSuccess(user: user, attendance: absen, type: type));
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

      // Get settings for check-out time
      final settings = await _settingsRepository.getSettings();
      final checkOutTime = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
        settings.checkOutHour,
        settings.checkOutMinute,
      );
      final type = DateTime.now().isBefore(checkOutTime)
          ? 'CheckIn'
          : 'CheckOut';

      // Check for existing attendance of the same type today
      final lastCheckIn = await _absenRepository
          .getLastAttendanceForUserAndType(event.userEmployeeId, 'CheckIn');
      final lastCheckOut = await _absenRepository
          .getLastAttendanceForUserAndType(event.userEmployeeId, 'CheckOut');

      if ((type == 'CheckIn' &&
              lastCheckIn != null &&
              DateTime.now().difference(lastCheckIn.jamAbsen).inSeconds <
                  cooldownSeconds) ||
          (type == 'CheckOut' &&
              lastCheckOut != null &&
              DateTime.now().difference(lastCheckOut.jamAbsen).inSeconds <
                  cooldownSeconds)) {
        final secondsRemaining =
            cooldownSeconds -
            DateTime.now()
                .difference(lastCheckIn?.jamAbsen ?? lastCheckOut!.jamAbsen)
                .inSeconds;
        emit(CooldownActive(secondsRemaining));
        return;
      }

      // Mark new attendance
      final newAttendance = AbsenModel(
        employeeId: event.userEmployeeId,
        nama: event.userName,
        jamAbsen: DateTime.now(),
      );

      // Check if late
      final isLate = await _isLateAttendance(newAttendance.jamAbsen, type);
      newAttendance.type = type;

      await _absenRepository.addAttendance(newAttendance);

      emit(
        AttendanceMarked(attendance: newAttendance, isLate: isLate, type: type),
      );
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

  Future<bool> _isLateAttendance(DateTime attendanceTime, String type) async {
    try {
      return await _settingsRepository.isLateTime(attendanceTime, type);
    } catch (e) {
      // Default to 9:00 AM for check-ins
      return type == 'CheckIn' &&
          (attendanceTime.hour > 9 ||
              (attendanceTime.hour == 9 && attendanceTime.minute > 0));
    }
  }
}
