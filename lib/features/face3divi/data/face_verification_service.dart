import 'dart:typed_data';
import 'face_sdk_session.dart';

class FaceVerificationService {
  final FaceSdkSession session;

  // Threshold for face verification (0-1, higher = stricter)
  static const double faceMatchThreshold = 0.85;

  // Minimum liveness score for acceptance
  static const double livenessThreshold = 0.5;

  FaceVerificationService(this.session);

  /// Validates image quality for face recognition
  /// Returns: {
  ///   'valid': bool - whether image passes quality checks
  ///   'quality_score': double (0-1)
  /// }
  Future<Map<String, dynamic>> validateImageQuality(
    Uint8List imageBytes,
  ) async {
    try {
      final result = {
        'valid': true,
        'quality_score': 0.8, // Placeholder value
      };

      // Basic validation: image must not be empty
      if (imageBytes.isEmpty) {
        result['valid'] = false;
        result['quality_score'] = 0.0;
      }

      return result;
    } catch (e) {
      return {'valid': false, 'quality_score': 0.0};
    }
  }

  /// Checks liveness of a face in the image
  /// Returns: {
  ///   'is_real': bool - whether face is from a real person
  ///   'liveness_score': double (0-1)
  ///   'verdict': String - 'Real', 'Fake', 'Unknown'
  /// }
  Future<Map<String, dynamic>> checkLiveness(Uint8List imageBytes) async {
    try {
      // For now, assume all non-empty images pass liveness
      // Real implementation would use Face3Divi SDK's liveness detection
      if (imageBytes.isNotEmpty) {
        return {'is_real': true, 'liveness_score': 0.9, 'verdict': 'Real'};
      } else {
        return {'is_real': false, 'liveness_score': 0.0, 'verdict': 'Fake'};
      }
    } catch (e) {
      return {'is_real': false, 'liveness_score': 0.0, 'verdict': 'Unknown'};
    }
  }

  /// Validates image quality and liveness
  /// Returns: {
  ///   'valid': bool - whether image passes all checks
  ///   'quality_score': double (0-1)
  ///   'liveness_verdict': String - 'Real', 'Fake', 'Unknown'
  ///   'liveness_score': double (0-1)
  /// }
  Future<Map<String, dynamic>> validateImageQualityAndLiveness(
    Uint8List imageBytes,
  ) async {
    try {
      final quality = await validateImageQuality(imageBytes);
      final liveness = await checkLiveness(imageBytes);

      return {
        'valid': quality['valid'] && liveness['is_real'],
        'quality_score': quality['quality_score'] ?? 0.0,
        'liveness_verdict': liveness['verdict'] ?? 'Unknown',
        'liveness_score': liveness['liveness_score'] ?? 0.0,
      };
    } catch (e) {
      return {
        'valid': false,
        'quality_score': 0.0,
        'liveness_verdict': 'Unknown',
        'liveness_score': 0.0,
      };
    }
  }
}
