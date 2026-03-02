import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:face_sdk_3divi/face_sdk_3divi.dart';
// ignore: depend_on_referenced_packages
import 'package:image/image.dart' as img_lib;

import '../../data/user_repository.dart';
import '../../data/face_sdk_repository.dart';
import '../../../../models/user_model.dart';
import '../../../../core/constants/face_recognition_config.dart';

// Events
abstract class UserRegistrationEvent {}

class StartFaceCaptureEvent extends UserRegistrationEvent {}

class CaptureFacePhotoEvent extends UserRegistrationEvent {
  final String imagePath;
  CaptureFacePhotoEvent(this.imagePath);
}

class RegisterUserEvent extends UserRegistrationEvent {
  final RegisteredUser user;

  RegisterUserEvent({required this.user});
}

class ResetRegistrationEvent extends UserRegistrationEvent {}

// States
abstract class UserRegistrationState {
  const UserRegistrationState();
}

class UserRegistrationInitial extends UserRegistrationState {
  const UserRegistrationInitial();
}

class FaceCaptureReady extends UserRegistrationState {
  final AsyncCapturer capturer;
  final AsyncProcessingBlock templateExtractor;
  final AsyncProcessingBlock qaa;

  const FaceCaptureReady({
    required this.capturer,
    required this.templateExtractor,
    required this.qaa,
  });
}

class FaceCaptureLoading extends UserRegistrationState {
  const FaceCaptureLoading();
}

class FacePhotoProcessing extends UserRegistrationState {
  const FacePhotoProcessing();
}

class FacePhotoProcessed extends UserRegistrationState {
  final Uint8List croppedFaceBytes;
  final Uint8List fullImageBytes;
  final double qualityScore;

  const FacePhotoProcessed({
    required this.croppedFaceBytes,
    required this.fullImageBytes,
    required this.qualityScore,
  });
}

class FacePhotoError extends UserRegistrationState {
  final String message;
  const FacePhotoError(this.message);
}

class UserRegistrationLoading extends UserRegistrationState {
  const UserRegistrationLoading();
}

class UserRegistrationSuccess extends UserRegistrationState {
  final String message;
  const UserRegistrationSuccess(this.message);
}

class UserRegistrationError extends UserRegistrationState {
  final String message;
  const UserRegistrationError(this.message);
}

// BLoC
class UserRegistrationBloc
    extends Bloc<UserRegistrationEvent, UserRegistrationState> {
  final UserRepository _userRepository;
  final FaceSdkRepository _faceSdkRepository;

  AsyncCapturer? _capturer;
  AsyncProcessingBlock? _templateExtractor;
  AsyncProcessingBlock? _qaa;
  Context? _faceTemplate;
  Uint8List? _processedImageBytes;

  UserRegistrationBloc({
    required UserRepository userRepository,
    required FaceSdkRepository faceSdkRepository,
  }) : _userRepository = userRepository,
       _faceSdkRepository = faceSdkRepository,
       super(const UserRegistrationInitial()) {
    on<StartFaceCaptureEvent>(_onStartFaceCapture);
    on<CaptureFacePhotoEvent>(_onCaptureFacePhoto);
    on<RegisterUserEvent>(_onRegisterUser);
    on<ResetRegistrationEvent>(_onResetRegistration);
  }

  Future<void> _onStartFaceCapture(
    StartFaceCaptureEvent event,
    Emitter<UserRegistrationState> emit,
  ) async {
    try {
      emit(const FaceCaptureLoading());

      // Give time for any previous page's resources to fully dispose
      await Future.delayed(const Duration(milliseconds: 500));

      // Get existing Face SDK session (reuses existing session, no double-init)
      final session = await _faceSdkRepository.getSession();

      // Retry logic for capturer creation (in case of license conflicts)
      int retryCount = 0;
      const maxRetries = 3;
      AsyncCapturer? capturer;

      while (retryCount < maxRetries) {
        try {
          // Create capturer for face detection
          capturer = await session.service.createAsyncCapturer(
            Config("common_capturer_blf_fda_front.xml"),
          );
          break; // Success, exit retry loop
        } catch (e) {
          retryCount++;
          if (retryCount >= maxRetries) {
            rethrow;
          }
          // Wait before retry (give time for other resources to clean up)
          await Future.delayed(Duration(milliseconds: 500 * retryCount));
        }
      }

      if (capturer == null) {
        emit(
          const FacePhotoError(
            'Failed to create face capturer after multiple attempts',
          ),
        );
        return;
      }

      _capturer = capturer;
      _templateExtractor = session.templateExtractor;
      _qaa = session.qaa;

      emit(
        FaceCaptureReady(
          capturer: _capturer!,
          templateExtractor: _templateExtractor!,
          qaa: _qaa!,
        ),
      );
    } catch (e) {
      final errorMessage = e.toString();
      if (errorMessage.contains('license') ||
          errorMessage.contains('License')) {
        emit(
          const FacePhotoError(
            'License conflict detected. Please wait a moment and try again, or fully restart the app.',
          ),
        );
      } else {
        emit(FacePhotoError('Failed to initialize face capture: $e'));
      }
    }
  }

  Future<void> _onCaptureFacePhoto(
    CaptureFacePhotoEvent event,
    Emitter<UserRegistrationState> emit,
  ) async {
    try {
      emit(const FacePhotoProcessing());

      if (_capturer == null || _templateExtractor == null || _qaa == null) {
        emit(
          const FacePhotoError('Face capture not initialized. Please restart.'),
        );
        return;
      }

      // Read image file
      final imageFile = File(event.imagePath);
      final Uint8List imageBytes = await imageFile.readAsBytes();

      // Detect faces in the image
      final List<RawSample> faces = await _capturer!.capture(imageBytes);

      if (faces.isEmpty) {
        emit(
          const FacePhotoError(
            'No face detected. Please try again with a clear face photo.',
          ),
        );
        return;
      }

      if (faces.length > 1) {
        // Clean up
        for (var face in faces) {
          face.dispose();
        }
        emit(
          const FacePhotoError(
            'Multiple faces detected. Please ensure only one face is visible.',
          ),
        );
        return;
      }

      // Process single face
      final RawSample face = faces.first;
      final rect = face.getRectangle();

      // Create context for quality assessment (reuse existing session)
      final session = await _faceSdkRepository.getSession();
      Context data = session.service.createContextFromEncodedImage(imageBytes);
      data["objects"].pushBack(face.toContext());

      Context object = data["objects"][0];

      // Perform quality assessment
      await _qaa!.process(data);

      final double qualityScore = object["quality"]["total_score"].get_value();

      if (qualityScore < FaceRecognitionConfig.minQualityScore) {
        data.dispose();
        face.dispose();
        emit(
          const FacePhotoError(
            'Photo quality too low (blurry or poor lighting). Please retake.',
          ),
        );
        return;
      }

      // Extract face template
      await _templateExtractor!.process(data);

      // Store template for later use
      _faceTemplate = session.service.createContext(object["face_template"]);

      // Crop face from image
      final croppedFaceBytes = await _cropFaceFromImage(imageBytes, rect);

      _processedImageBytes = croppedFaceBytes;

      // Clean up
      data.dispose();
      face.dispose();

      emit(
        FacePhotoProcessed(
          croppedFaceBytes: croppedFaceBytes,
          fullImageBytes: imageBytes,
          qualityScore: qualityScore,
        ),
      );
    } catch (e) {
      emit(FacePhotoError('Error processing photo: $e'));
    }
  }

  Future<void> _onRegisterUser(
    RegisterUserEvent event,
    Emitter<UserRegistrationState> emit,
  ) async {
    try {
      emit(const UserRegistrationLoading());

      // Validate required data
      if (_processedImageBytes == null) {
        emit(
          const UserRegistrationError(
            'No face photo captured. Please capture a photo first.',
          ),
        );
        return;
      }

      if (_faceTemplate == null) {
        emit(
          const UserRegistrationError(
            'Face template not generated. Please capture photo again.',
          ),
        );
        return;
      }

      // Check if user already exists
      if (_userRepository.existsByNik(event.user.nik)) {
        emit(
          UserRegistrationError(
            'User with NIK ${event.user.nik} already exists.',
          ),
        );
        return;
      }

      // Create new user
      final newUser = RegisteredUser(
        nik: event.user.nik,
        nama: event.user.nama,
        imageBytes: _processedImageBytes!,
        templateBytes: _processedImageBytes,
        hasTemplate: true,
        isAdmin: event.user.isAdmin,
        department: event.user.department,
        employeeId: event.user.employeeId,
        employeeRole: event.user.employeeRole,
        companyCode: event.user.companyCode,
        estateCode: event.user.estateCode,
        plantCode: event.user.plantCode,
        rawUserJson: event.user.rawUserJson,
      );

      // Save to repository (Hive)
      await _userRepository.addUser(newUser);

      emit(
        UserRegistrationSuccess(
          'User "${event.user.nama}" registered successfully!',
        ),
      );

      // Auto-reset after success
      add(ResetRegistrationEvent());
    } catch (e) {
      emit(UserRegistrationError('Failed to register user: $e'));
    }
  }

  Future<void> _onResetRegistration(
    ResetRegistrationEvent event,
    Emitter<UserRegistrationState> emit,
  ) async {
    // Clean up resources
    _faceTemplate?.dispose();
    _faceTemplate = null;
    _processedImageBytes = null;

    emit(const UserRegistrationInitial());
  }

  Future<Uint8List> _cropFaceFromImage(
    Uint8List imageBytes,
    Rectangle rect,
  ) async {
    // Decode image
    img_lib.Image? originalImage = img_lib.decodeImage(imageBytes);

    if (originalImage == null) {
      throw Exception('Failed to decode image');
    }

    // Calculate crop bounds with padding
    final padding = 20;
    final x = (rect.x - padding).clamp(0, originalImage.width).toInt();
    final y = (rect.y - padding).clamp(0, originalImage.height).toInt();
    final w = (rect.width + padding * 2)
        .clamp(0, originalImage.width - x)
        .toInt();
    final h = (rect.height + padding * 2)
        .clamp(0, originalImage.height - y)
        .toInt();

    // Crop face region
    final croppedImage = img_lib.copyCrop(
      originalImage,
      x: x,
      y: y,
      width: w,
      height: h,
    );

    // Encode back to bytes
    return Uint8List.fromList(img_lib.encodeJpg(croppedImage, quality: 90));
  }

  @override
  Future<void> close() async {
    // Dispose capturer first (most likely to cause conflicts)
    try {
      await _capturer?.dispose();
    } catch (e) {
      // Ignore disposal errors
    }

    // Note: Don't dispose templateExtractor, qaa as they're shared from session
    // Only dispose resources we created (capturer)

    // Dispose face template context
    try {
      _faceTemplate?.dispose();
    } catch (e) {
      // Ignore disposal errors
    }

    return super.close();
  }
}
