import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fr3divi/features/face3divi/data/face_sdk_repository.dart';
import 'package:fr3divi/features/face3divi/data/face_sdk_session.dart';
import 'package:fr3divi/features/face3divi/data/face_verification_service.dart';
import 'package:fr3divi/core/services/logger_service.dart';
import 'package:fr3divi/core/di/service_locator.dart';

// Events
abstract class FaceSdkEvent {}

class InitializeFaceSdkEvent extends FaceSdkEvent {}

class DisposeFaceSdkEvent extends FaceSdkEvent {}

// States
abstract class FaceSdkState {
  const FaceSdkState();
}

class FaceSdkLoading extends FaceSdkState {
  const FaceSdkLoading();
}

class FaceSdkReady extends FaceSdkState {
  final FaceSdkSession session;
  const FaceSdkReady(this.session);
}

class FaceSdkError extends FaceSdkState {
  final String message;
  const FaceSdkError(this.message);
}

// BLoC
class FaceSdkBloc extends Bloc<FaceSdkEvent, FaceSdkState> {
  final FaceSdkRepository _repository;
  FaceSdkSession? _currentSession;

  FaceSdkBloc(this._repository) : super(const FaceSdkLoading()) {
    on<InitializeFaceSdkEvent>(_onInitialize);
    on<DisposeFaceSdkEvent>(_onDispose);
  }

  Future<void> _onInitialize(
    InitializeFaceSdkEvent event,
    Emitter<FaceSdkState> emit,
  ) async {
    try {
      emit(const FaceSdkLoading());
      logger.info('Initializing Face SDK...', tag: 'FaceSdkBloc');
      _currentSession = await _repository.getSession();
      serviceLocator.setFaceVerificationService(
        FaceVerificationService(_currentSession!),
      );
      logger.info('Face SDK initialized successfully', tag: 'FaceSdkBloc');
      emit(FaceSdkReady(_currentSession!));
    } catch (e) {
      logger.error('Face SDK initialization failed: $e', tag: 'FaceSdkBloc');
      emit(FaceSdkError(_formatInitError(e)));
    }
  }

  Future<void> _onDispose(
    DisposeFaceSdkEvent event,
    Emitter<FaceSdkState> emit,
  ) async {
    try {
      logger.info('Disposing Face SDK...', tag: 'FaceSdkBloc');
      await _repository.disposeSession();
      _currentSession = null;
      serviceLocator.setFaceVerificationService(null);
      logger.info('Face SDK disposed successfully', tag: 'FaceSdkBloc');
      emit(const FaceSdkLoading());
    } catch (e) {
      logger.error(
        'Error disposing Face SDK: $e',
        tag: 'FaceSdkBloc',
        error: e as Error?,
      );
      emit(FaceSdkError(e.toString()));
    }
  }

  FaceSdkSession? get currentSession => _currentSession;

  String _formatInitError(Object error) {
    final message = error.toString();
    if (message.contains('is_accept_license')) {
      return '$message\n\nHot restart is not supported by the Face SDK license. Fully close the app (swipe away) and launch again.';
    }
    return message;
  }

  @override
  Future<void> close() async {
    logger.info(
      'FaceSdkBloc closing, disposing session...',
      tag: 'FaceSdkBloc',
    );
    try {
      await _repository.disposeSession();
      serviceLocator.setFaceVerificationService(null);
      logger.info(
        'FaceSdkBloc disposed session successfully',
        tag: 'FaceSdkBloc',
      );
    } catch (e) {
      logger.error(
        'Error in FaceSdkBloc.close(): $e',
        tag: 'FaceSdkBloc',
        error: e as Error?,
      );
    }
    return super.close();
  }
}
