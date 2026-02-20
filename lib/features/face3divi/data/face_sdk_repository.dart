import 'face_sdk_data_source.dart';
import 'face_sdk_session.dart';

class FaceSdkRepository {
  FaceSdkRepository(this._dataSource);

  final FaceSdkDataSource _dataSource;
  FaceSdkSession? _session;
  Future<FaceSdkSession>? _initFuture;
  bool _isDisposing = false;

  Future<FaceSdkSession> getSession() async {
    final existing = _session;
    if (existing != null) {
      return existing;
    }

    // Ensure any in-flight operation completes
    final inFlight = _initFuture;
    if (inFlight != null) {
      try {
        return await inFlight;
      } catch (_) {
        _initFuture = null;
        // If initialization failed, try again
      }
    }

    final future = _dataSource.createSession();
    _initFuture = future;
    try {
      final session = await future;
      _session = session;
      return session;
    } catch (e) {
      _initFuture = null;
      rethrow;
    } finally {
      // Ensure we clear the future reference even on success
      if (_initFuture == future) {
        _initFuture = null;
      }
    }
  }

  Future<void> disposeSession() async {
    if (_isDisposing) {
      return;
    }
    _isDisposing = true;
    try {
      final inFlight = _initFuture;
      if (inFlight != null) {
        try {
          await inFlight;
        } catch (_) {}
      }

      final session = _session;
      _session = null;
      if (session != null) {
        await session.dispose();
      }
    } finally {
      _isDisposing = false;
    }
  }
}
