import 'package:camera/camera.dart';

class CameraService {
  Future<List<CameraDescription>> getAvailableCameras() async {
    return availableCameras();
  }
}
