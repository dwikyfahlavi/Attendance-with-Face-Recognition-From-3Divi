import 'package:face_sdk_3divi/face_sdk_3divi.dart';

import '../face_sdk_session.dart';

class FaceSdkDataSource {
  Future<FaceSdkSession> createSession() async {
    try {
      final FacerecService service = await FaceSdkPlugin.createFacerecService();

      final AsyncProcessingBlock templateExtractor = await service
          .createAsyncProcessingBlock({
            "unit_type": "FACE_TEMPLATE_EXTRACTOR",
            "modification": "30",
            "config": {"without_objects": true},
          });

      final AsyncProcessingBlock qaa = await service
          .createAsyncProcessingBlock({
            "unit_type": "QUALITY_ASSESSMENT_ESTIMATOR",
            "modification": "assessment",
            "config_name": "quality_assessment.xml",
            "version": 1,
          });

      final AsyncProcessingBlock verification = await service
          .createAsyncProcessingBlock({
            "unit_type": "VERIFICATION_MODULE",
            "modification": "30",
          });

      return FaceSdkSession(
        service: service,
        templateExtractor: templateExtractor,
        qaa: qaa,
        verification: verification,
      );
    } catch (e) {
      rethrow;
    }
  }
}
