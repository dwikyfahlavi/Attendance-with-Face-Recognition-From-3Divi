import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:face_sdk_3divi/face_sdk_3divi.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img_lib;

import '../../../../core/constants/face_recognition_config.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../widgets/modern_button.dart';

class MemberTemplateCapturePage extends StatefulWidget {
  const MemberTemplateCapturePage({super.key});

  @override
  State<MemberTemplateCapturePage> createState() =>
      _MemberTemplateCapturePageState();
}

class _MemberTemplateCapturePageState extends State<MemberTemplateCapturePage> {
  CameraController? _controller;
  bool _isInitializing = true;
  bool _isCapturing = false;
  List<CameraDescription> _cameras = [];
  CameraLensDirection _currentLensDirection = CameraLensDirection.back;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      await _initializeCamera(_currentLensDirection);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isInitializing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to initialize camera'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  Future<void> _initializeCamera(CameraLensDirection lensDirection) async {
    final selected = _cameras.firstWhere(
      (camera) => camera.lensDirection == lensDirection,
      orElse: () => _cameras.first,
    );

    final previousController = _controller;
    final controller = CameraController(
      selected,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await controller.initialize();
    await _configureDefaultZoom(controller);

    if (!mounted) {
      await controller.dispose();
      return;
    }

    setState(() {
      _controller = controller;
      _currentLensDirection = selected.lensDirection;
      _isInitializing = false;
    });

    await previousController?.dispose();
  }

  Future<void> _toggleCamera() async {
    if (_isInitializing || _isCapturing || _cameras.isEmpty) {
      return;
    }

    final targetLens = _currentLensDirection == CameraLensDirection.back
        ? CameraLensDirection.front
        : CameraLensDirection.back;

    setState(() {
      _isInitializing = true;
    });

    try {
      await _initializeCamera(targetLens);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isInitializing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to switch camera'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  Future<void> _configureDefaultZoom(CameraController controller) async {
    try {
      final minZoom = await controller.getMinZoomLevel();
      final maxZoom = await controller.getMaxZoomLevel();
      final targetZoom = (minZoom + 0.1).clamp(minZoom, maxZoom);
      await controller.setZoomLevel(targetZoom);
    } catch (_) {
      // Ignore zoom configuration errors on unsupported devices.
    }
  }

  Future<void> _captureTemplate() async {
    if (_isCapturing ||
        _controller == null ||
        !_controller!.value.isInitialized) {
      return;
    }

    setState(() {
      _isCapturing = true;
    });

    try {
      final photo = await _controller!.takePicture();
      final bytes = await photo.readAsBytes();

      final validationResult = await _validateCapturedFace(bytes);
      if (validationResult.errorMessage != null) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(validationResult.errorMessage!),
            backgroundColor: AppColors.warningOrange,
          ),
        );
        return;
      }

      if (!mounted) return;
      Navigator.of(context).pop<Uint8List>(validationResult.croppedBytes!);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to capture photo'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  Future<_CaptureValidationResult> _validateCapturedFace(
    Uint8List imageBytes,
  ) async {
    AsyncCapturer? capturer;
    Context? data;
    RawSample? sample;

    try {
      final session = await serviceLocator.faceSdkRepository.getSession();
      capturer = await session.service.createAsyncCapturer(
        Config("common_capturer_blf_fda_front.xml"),
      );

      final samples = await capturer.capture(imageBytes);
      if (samples.isEmpty) {
        return const _CaptureValidationResult(
          errorMessage: 'No face detected. Please face the camera clearly.',
        );
      }

      if (samples.length > 1) {
        for (final item in samples) {
          item.dispose();
        }
        return const _CaptureValidationResult(
          errorMessage:
              'Multiple faces detected. Make sure only one face is visible.',
        );
      }

      sample = samples.first;
      final faceRect = sample.getRectangle();
      data = session.service.createContextFromEncodedImage(imageBytes);
      data["objects"].pushBack(sample.toContext());

      await session.qaa.process(data);
      final quality =
          data["objects"][0]["quality"]["total_score"].get_value() as double?;

      if (quality == null || quality < FaceRecognitionConfig.minQualityScore) {
        return const _CaptureValidationResult(
          errorMessage:
              'Low face quality. Improve lighting and keep face centered.',
        );
      }

      await session.templateExtractor.process(data);
      final croppedBytes = _cropFaceFromImage(imageBytes, faceRect);
      return _CaptureValidationResult(croppedBytes: croppedBytes);
    } catch (_) {
      return const _CaptureValidationResult(
        errorMessage: 'Failed to validate face template. Please try again.',
      );
    } finally {
      try {
        data?.dispose();
      } catch (_) {}
      try {
        sample?.dispose();
      } catch (_) {}
      try {
        await capturer?.dispose();
      } catch (_) {}
    }
  }

  Uint8List _cropFaceFromImage(Uint8List imageBytes, Rectangle rect) {
    final originalImage = img_lib.decodeImage(imageBytes);
    if (originalImage == null) {
      return imageBytes;
    }

    final dynamicPadding =
        (rect.width > rect.height ? rect.width : rect.height) * 0.55;
    final padding = dynamicPadding < 32 ? 32 : dynamicPadding;

    final x = (rect.x - padding).clamp(0, originalImage.width).toInt();
    final y = (rect.y - padding).clamp(0, originalImage.height).toInt();
    final w = (rect.width + padding * 2)
        .clamp(1, originalImage.width - x)
        .toInt();
    final h = (rect.height + padding * 2)
        .clamp(1, originalImage.height - y)
        .toInt();

    final croppedImage = img_lib.copyCrop(
      originalImage,
      x: x,
      y: y,
      width: w,
      height: h,
    );

    return Uint8List.fromList(img_lib.encodeJpg(croppedImage, quality: 90));
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Capture Face Template'),
        elevation: 0,
        backgroundColor: AppColors.backgroundWhite,
        actions: [
          IconButton(
            onPressed: _toggleCamera,
            tooltip: 'Switch camera',
            icon: const Icon(Icons.cameraswitch),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  color: Colors.black,
                  child: _isInitializing
                      ? const Center(child: CircularProgressIndicator())
                      : _controller == null
                      ? Center(
                          child: Text(
                            'Camera unavailable',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        )
                      : CameraPreview(_controller!),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ModernButton(
                label: 'Capture Template',
                onPressed: _captureTemplate,
                isLoading: _isCapturing,
                isEnabled: !_isInitializing && _controller != null,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Quality check follows registration rules (single face + minimum quality).',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _CaptureValidationResult {
  final String? errorMessage;
  final Uint8List? croppedBytes;

  const _CaptureValidationResult({this.errorMessage, this.croppedBytes});
}
