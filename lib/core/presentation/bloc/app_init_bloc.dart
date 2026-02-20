import 'package:camera/camera.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fr3divi/core/services/camera_service.dart';

// Events
abstract class AppInitEvent {}

class InitializeAppEvent extends AppInitEvent {}

// States
abstract class AppInitState {
  final List<CameraDescription> cameras;
  final bool isLoading;
  final String? error;

  AppInitState({this.cameras = const [], this.isLoading = false, this.error});
}

class AppInitLoading extends AppInitState {
  AppInitLoading() : super(isLoading: true);
}

class AppInitReady extends AppInitState {
  AppInitReady({required super.cameras}) : super(isLoading: false);
}

class AppInitError extends AppInitState {
  AppInitError({required String error}) : super(error: error, isLoading: false);
}

// BLoC
class AppInitBloc extends Bloc<AppInitEvent, AppInitState> {
  final CameraService _cameraService;

  AppInitBloc(this._cameraService) : super(AppInitLoading()) {
    on<InitializeAppEvent>(_onInitialize);
  }

  Future<void> _onInitialize(
    InitializeAppEvent event,
    Emitter<AppInitState> emit,
  ) async {
    try {
      emit(AppInitLoading());
      final cameras = await _cameraService.getAvailableCameras();
      emit(AppInitReady(cameras: cameras));
    } catch (e) {
      emit(AppInitError(error: e.toString()));
    }
  }
}
