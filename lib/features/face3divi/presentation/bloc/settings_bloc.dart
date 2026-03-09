import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repository/settings_repository.dart';
import '../../data/models/settings_model.dart';

// Events
abstract class SettingsEvent {}

class LoadSettingsEvent extends SettingsEvent {}

class UpdateFaceRecognitionEvent extends SettingsEvent {
  final bool enabled;
  UpdateFaceRecognitionEvent(this.enabled);
}

class UpdateCheckInOutHoursEvent extends SettingsEvent {
  final int checkInHour;
  final int checkInMinute;
  final int checkOutHour;
  final int checkOutMinute;
  UpdateCheckInOutHoursEvent({
    required this.checkInHour,
    required this.checkInMinute,
    required this.checkOutHour,
    required this.checkOutMinute,
  });
}

class UpdateApiConfigEvent extends SettingsEvent {
  final String ipPort;
  final String? baseProtocol;
  final String? apiPath;

  UpdateApiConfigEvent({required this.ipPort, this.baseProtocol, this.apiPath});
}

// States
abstract class SettingsState {
  const SettingsState();
}

class SettingsInitial extends SettingsState {
  const SettingsInitial();
}

class SettingsLoading extends SettingsState {
  const SettingsLoading();
}

class SettingsLoaded extends SettingsState {
  final SettingsModel settings;
  const SettingsLoaded(this.settings);
}

class SettingsError extends SettingsState {
  final String message;
  const SettingsError(this.message);
}

// BLoC
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final SettingsRepository _repository;

  SettingsBloc(this._repository) : super(const SettingsInitial()) {
    on<LoadSettingsEvent>(_onLoadSettings);
    on<UpdateFaceRecognitionEvent>(_onUpdateFaceRecognition);
    on<UpdateCheckInOutHoursEvent>(_onUpdateCheckInOutHours);
    on<UpdateApiConfigEvent>(_onUpdateApiConfig);
  }

  Future<void> _onLoadSettings(
    LoadSettingsEvent event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      emit(const SettingsLoading());
      final settings = await _repository.getSettings();
      emit(SettingsLoaded(settings));
    } catch (e) {
      emit(SettingsError(e.toString()));
    }
  }

  Future<void> _onUpdateFaceRecognition(
    UpdateFaceRecognitionEvent event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      await _repository.setFaceRecognitionEnabled(event.enabled);
      final settings = await _repository.getSettings();
      emit(SettingsLoaded(settings));
    } catch (e) {
      emit(SettingsError(e.toString()));
    }
  }

  Future<void> _onUpdateCheckInOutHours(
    UpdateCheckInOutHoursEvent event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      await _repository.setCheckInOutHours(
        event.checkInHour,
        event.checkInMinute,
        event.checkOutHour,
        event.checkOutMinute,
      );
      final settings = await _repository.getSettings();
      emit(SettingsLoaded(settings));
    } catch (e) {
      emit(SettingsError(e.toString()));
    }
  }

  Future<void> _onUpdateApiConfig(
    UpdateApiConfigEvent event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      await _repository.setApiConfig(
        ipPort: event.ipPort,
        baseProtocol: event.baseProtocol,
        apiPath: event.apiPath,
      );
      final settings = await _repository.getSettings();
      emit(SettingsLoaded(settings));
    } catch (e) {
      emit(SettingsError(e.toString()));
    }
  }
}
