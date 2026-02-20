import 'package:face_sdk_3divi/face_sdk_3divi.dart';

class FaceSdkSession {
  final FacerecService service;
  final AsyncProcessingBlock templateExtractor;
  final AsyncProcessingBlock qaa;
  final AsyncProcessingBlock verification;
  bool _isDisposed = false;

  FaceSdkSession({
    required this.service,
    required this.templateExtractor,
    required this.qaa,
    required this.verification,
  });

  Future<void> dispose() async {
    if (_isDisposed) return;
    _isDisposed = true;

    try {
      await templateExtractor.dispose();
    } catch (_) {}
    try {
      await qaa.dispose();
    } catch (_) {}
    try {
      await verification.dispose();
    } catch (_) {}

    // Dispose the FacerecService to release the license
    // This must be done after processing blocks are disposed
    try {
      service.dispose();
    } catch (_) {}
  }
}
