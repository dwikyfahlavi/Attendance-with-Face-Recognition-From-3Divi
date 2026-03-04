import 'dart:io';
import 'dart:ui' as ui;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:camera/camera.dart';
import 'package:face_sdk_3divi/face_sdk_3divi.dart';
import 'package:face_sdk_3divi/utils.dart';
import 'dart:ffi' as ffi;
import 'package:intl/intl.dart';

import '../../../../models/user_model.dart';
import '../../../../models/absen_model.dart';
import '../../../../core/constants/face_recognition_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/services/audio_service.dart';
import '../../../../core/di/service_locator.dart';
import '../../data/face_sdk_session.dart';
import '../bloc/attendance_scan_bloc.dart';

class UserAttendanceScanPage extends StatefulWidget {
  const UserAttendanceScanPage({super.key});

  @override
  State<UserAttendanceScanPage> createState() => _UserAttendanceScanPageState();
}

class _UserAttendanceScanPageState extends State<UserAttendanceScanPage> {
  late CameraController controller;
  AsyncVideoWorker? _videoWorker;
  AsyncProcessingBlock? liveness;
  final GlobalKey _pictureKey = GlobalKey();
  int baseAngle = 0;
  String _livenessResult = "Processing";
  bool isReady = true;
  Offset? widgetPosition;
  ui.Size? widgetSize;
  Widget? bboxWidget;
  bool flipX = true;
  bool _isDisposing = false;
  bool _isSwitching = false;
  bool _isInitialized = false;
  bool _isExiting = false;

  DateTime? _lastAbsenTime;
  String? _lastAbsenEmployeeId;

  double _qaaTotalScore = 0.0;
  int currentCameraIndex = 0;

  RegisteredUser? matchedUser;
  double? matchedScore;
  Widget? matchedImage;
  bool? matchedIsReal;
  List<_DBUserTemplate> dbTemplates = [];

  // Face SDK components
  FaceSdkSession? _faceSdkSession;
  List<CameraDescription> cameras = [];

  // Banner notification
  String? _topBanner;
  Color _topBannerColor = Colors.green;
  Timer? _bannerTimer;

  void showTopBanner(String message, {Color? color, int seconds = 2}) {
    _bannerTimer?.cancel();
    if (mounted) {
      setState(() {
        _topBanner = message;
        _topBannerColor = color ?? Colors.green;
      });
    }
    _bannerTimer = Timer(Duration(seconds: seconds), () {
      if (mounted) setState(() => _topBanner = null);
    });
  }

  @override
  void initState() {
    super.initState();
    _initializeEverything();
  }

  Future<void> _initializeEverything() async {
    try {
      // Get Face SDK session
      _faceSdkSession = await serviceLocator.faceSdkRepository.getSession();

      // Get cameras
      cameras = await availableCameras();

      if (cameras.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No camera found on this device'),
              backgroundColor: AppColors.errorRed,
            ),
          );
        }
        return;
      }

      if (Platform.isIOS) flipX = false;

      final rearIndex = cameras.indexWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
      );
      currentCameraIndex = rearIndex >= 0 ? rearIndex : 0;

      // Initialize liveness
      liveness = await _faceSdkSession!.service.createAsyncProcessingBlock({
        "unit_type": "LIVENESS_ESTIMATOR",
        "modification": "2d_light",
        "version": 1,
      });

      // Initialize video worker
      _videoWorker = await _faceSdkSession!.service.createAsyncVideoWorker(
        VideoWorkerParams()
            .video_worker_config(
              Config("video_worker_fdatracker_pb_blf_fda_front.xml"),
            )
            .streams_count(1),
      );

      // Prepare database templates
      await _prepareDbTemplates();

      // Initialize camera
      await _initCamera(currentCameraIndex);

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to initialize: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _prepareDbTemplates() async {
    if (_faceSdkSession == null) return;

    dbTemplates.clear();
    final box = serviceLocator.userBox;
    final service = _faceSdkSession!.service;
    final qaa = _faceSdkSession!.qaa;
    final templateExtractor = _faceSdkSession!.templateExtractor;

    AsyncCapturer? capturer;
    try {
      capturer = await service.createAsyncCapturer(
        Config("common_capturer_blf_fda_front.xml"),
      );

      for (final user in box.values) {
        try {
          final templateSourceBytes = user.imageBytes;
          if (templateSourceBytes == null) {
            continue;
          }
          final List<RawSample> rss = await capturer.capture(
            templateSourceBytes,
          );
          if (rss.isEmpty) continue;

          Context data = service.createContextFromEncodedImage(
            templateSourceBytes,
          );
          data["objects"].pushBack(rss[0].toContext());

          await qaa.process(data);
          await templateExtractor.process(data);

          final Context template = service.createContext(
            data["objects"][0]["face_template"],
          );

          dbTemplates.add(_DBUserTemplate(user: user, template: template));

          rss[0].dispose();
          data.dispose();
        } catch (e) {
          // print('yahuy : ${e.toString()}');
          // Skip users that fail processing
          continue;
        }
      }
    } finally {
      await capturer?.dispose();
    }

    if (mounted) setState(() {});
  }

  Future<void> stopCameraStreamIfNeeded() async {
    if (controller.value.isStreamingImages) {
      try {
        await controller.stopImageStream();
        await Future.delayed(const Duration(milliseconds: 300));
      } catch (e) {
        // Ignore errors when stopping stream
      }
    }
  }

  Future<void> _initCamera(int camIndex) async {
    if (cameras.isEmpty) return;
    try {
      controller = CameraController(
        cameras[camIndex],
        ResolutionPreset.high,
        enableAudio: false,
      );
      await controller.initialize();
      baseAngle = getBaseAngle(controller);

      if (!mounted) return;

      setState(() {});

      if (!controller.value.isStreamingImages) {
        await controller.startImageStream(_processStream);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to initialize camera: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _disposeControllerSafely() async {
    try {
      if (controller.value.isStreamingImages) {
        await stopCameraStreamIfNeeded();
      }
      await controller.dispose();
    } catch (_) {
      // Ignore camera dispose race from CameraX plugin.
    }
  }

  Future<void> changeCamera() async {
    if (_isSwitching || _isDisposing || cameras.length < 2) return;
    _isSwitching = true;
    try {
      await _disposeControllerSafely();
      currentCameraIndex = (currentCameraIndex + 1) % cameras.length;
      await _initCamera(currentCameraIndex);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to switch camera: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
    _isSwitching = false;
  }

  Future<void> _processStream(CameraImage image) async {
    if (_isDisposing ||
        _isSwitching ||
        !isReady ||
        _videoWorker == null ||
        !mounted ||
        dbTemplates.isEmpty ||
        liveness == null) {
      return;
    }
    isReady = false;

    final RenderBox? renderBox =
        _pictureKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      widgetPosition = renderBox.localToGlobal(Offset.zero);
      widgetSize = renderBox.size;
    }

    int width, height;
    switch (baseAngle) {
      case 1:
      case 2:
        width = image.height;
        height = image.width;
        break;
      default:
        width = image.width;
        height = image.height;
        break;
    }

    RawImageF? frame = await addVideoFrame(image);
    if (frame == null) {
      _resetMatch();
      bboxWidget = null;
      isReady = true;
      return;
    }

    RawSample? sample = await pool();
    if (sample == null) {
      _resetMatch();
      bboxWidget = null;
      isReady = true;
      return;
    }

    bboxWidget = buildBboxWidget(width, height, sample.getRectangle());
    if (mounted) setState(() {});

    await processFrame(width, height, frame, sample);
  }

  void _resetMatch() {
    if (mounted) {
      setState(() {
        matchedUser = null;
        matchedScore = null;
        matchedImage = null;
        matchedIsReal = null;
      });
    }
  }

  Future<RawImageF?> addVideoFrame(CameraImage cameraImage) async {
    if (!mounted || _faceSdkSession == null) {
      await Future.delayed(const Duration(milliseconds: 10));
      return null;
    }
    RawImageF target = _faceSdkSession!.service.createRawImageFromCameraImage(
      cameraImage,
      baseAngle,
    );
    await _videoWorker!.addVideoFrame(
      target,
      DateTime.now().microsecondsSinceEpoch,
    );
    await Future.delayed(const Duration(milliseconds: 10));
    return target;
  }

  Future<RawSample?> pool() async {
    if (_videoWorker == null || liveness == null || !mounted) {
      await Future.delayed(const Duration(milliseconds: 50));
      return null;
    }
    final TrackingData callbackData = await _videoWorker!.poolTrackResults();
    final List<RawSample> rawSamples =
        callbackData.tracking_callback_data.samples;
    if (rawSamples.length != 1) return null;
    return rawSamples.first;
  }

  Future<void> processFrame(
    int width,
    int height,
    RawImageF? frame,
    RawSample sample,
  ) async {
    if (_faceSdkSession == null) return;

    final ffi.Pointer<ffi.Uint8> ptr = frame!.data.cast<ffi.Uint8>();
    final bytes = ptr.asTypedList(width * height * 3);

    Context data = _faceSdkSession!.service.createContext({
      "objects": [sample.toContext()],
      "image": {
        "blob": bytes,
        "dtype": "uint8_t",
        "format": "NDARRAY",
        "shape": [height, width, 3],
      },
    });

    await _faceSdkSession!.qaa.process(data);
    Context object = data["objects"][0];
    _qaaTotalScore = object["quality"]["total_score"].get_value();

    if (_qaaTotalScore < FaceRecognitionConfig.minQualityScore) {
      _resetMatch();
      showTopBanner(
        "Low quality image, face the camera!",
        color: Colors.orange[800],
      );
      data.dispose();
      sample.dispose();
      frame.dispose();
      isReady = true;
      return;
    }

    await liveness!.process(data);
    bool isReal = object["liveness"]["value"].get_value() == "REAL";
    _livenessResult = isReal ? "Real" : "Fake";
    if (!isReal) {
      _resetMatch();
      showTopBanner(
        "Not a real face detected. Please try with real face.",
        color: Colors.red[700],
      );
      data.dispose();
      sample.dispose();
      frame.dispose();
      isReady = true;
      return;
    }

    await _faceSdkSession!.templateExtractor.process(data);
    Context liveTemplate = _faceSdkSession!.service.createContext(
      data["objects"][0]["face_template"],
    );
    await liveCompare(liveTemplate, isReal);

    liveTemplate.dispose();
    data.dispose();
    sample.dispose();
    frame.dispose();
    isReady = true;
  }

  Future<void> _tryInsertAbsen(RegisteredUser user) async {
    final now = DateTime.now();

    // Check cooldown
    if (_lastAbsenEmployeeId == user.employeeId && _lastAbsenTime != null) {
      final diff = now.difference(_lastAbsenTime!).inSeconds;
      if (diff < 10) return; // 10 second cooldown
    }

    // Emit event to BLoC instead of directly calling repository
    if (mounted) {
      context.read<AttendanceScanBloc>().add(RecordAttendanceEvent(user, now));
    }
  }

  Future<void> liveCompare(Context liveTemplate, bool isReal) async {
    if (_faceSdkSession == null) return;

    double highestScore = 0.0;
    _DBUserTemplate? bestMatch;

    try {
      for (final db in dbTemplates) {
        final compareCtx = _faceSdkSession!.service.createContext({
          "template1": db.template,
          "template2": liveTemplate,
        });
        await _faceSdkSession!.verification.process(compareCtx);

        final score = compareCtx["result"]["score"].get_value() ?? 0.0;

        if (score > highestScore) {
          highestScore = score;
          bestMatch = db;
        }
        compareCtx.dispose();
      }
    } catch (e) {
      // Ignore errors during template comparison
    }

    if (mounted) {
      setState(() {
        if (bestMatch != null &&
            highestScore > FaceRecognitionConfig.minMatchScore) {
          matchedUser = bestMatch.user;
          matchedScore = highestScore;
          final imageBytes = bestMatch.user.imageBytes;
          matchedImage = imageBytes == null
              ? const Icon(Icons.person, size: 60, color: AppColors.secondary)
              : Image.memory(imageBytes, width: 60, height: 60);
          matchedIsReal = isReal;
          _tryInsertAbsen(bestMatch.user);
        } else {
          matchedUser = null;
          matchedScore = null;
          matchedImage = null;
          matchedIsReal = null;
          showTopBanner(
            "Face not recognized in database!",
            color: Colors.red[600],
          );
        }
      });
    }
  }

  Widget? buildBboxWidget(int width, int height, Rectangle bbox) {
    if (widgetSize == null) return null;
    double xCoefficient = widgetSize!.width / width;
    double yCoefficient = widgetSize!.height / height;
    double widgetWidth = bbox.width * xCoefficient;
    double widgetHeight = bbox.height * yCoefficient;

    return Stack(
      children: [
        // Bounding box
        Positioned(
          left: widgetPosition!.dx + bbox.x * xCoefficient,
          top: widgetPosition!.dy + bbox.y * yCoefficient,
          width: widgetWidth,
          height: widgetHeight,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.secondary, width: 3.0),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        // Quality & Liveness badges
        Positioned(
          left: widgetPosition!.dx + bbox.x * xCoefficient,
          top: widgetPosition!.dy + bbox.y * yCoefficient + widgetHeight + 8,
          width: widgetWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _badgeInfo(
                "Quality: ${_qaaTotalScore.toStringAsFixed(3)}",
                color: _qaaTotalScore >= FaceRecognitionConfig.minQualityScore
                    ? AppColors.successGreen
                    : AppColors.warningOrange,
              ),
              const SizedBox(height: 3),
              _badgeInfo(
                "Liveness: $_livenessResult",
                color: _livenessResult == "Real"
                    ? AppColors.successGreen
                    : AppColors.errorRed,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _badgeInfo(String text, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 10),
      decoration: BoxDecoration(
        color: color ?? Colors.blueGrey,
        borderRadius: BorderRadius.circular(7),
        boxShadow: [
          BoxShadow(
            color: (color ?? Colors.blueGrey).withOpacity(0.11),
            blurRadius: 3,
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  void _showSuccessDialog(RegisteredUser user, AbsenModel absen) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.successGreen.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: AppColors.successGreen,
                  size: 50,
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                'Attendance Recorded!',
                style: AppTextStyles.headlineSmall.copyWith(
                  color: AppColors.successGreen,
                ),
              ),
              const SizedBox(height: 20),

              // User photo
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: user.imageBytes == null
                    ? Container(
                        width: 100,
                        height: 100,
                        color: AppColors.backgroundLight,
                        child: const Icon(
                          Icons.person,
                          color: AppColors.textSecondary,
                        ),
                      )
                    : Image.memory(
                        user.imageBytes!,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
              ),
              const SizedBox(height: 16),

              // User details
              _detailRow('Employee ID', user.employeeId),
              _detailRow('Name', user.employeeName),
              if (user.department != null)
                _detailRow('Department', user.department!),
              _detailRow('Time', DateFormat('HH:mm:ss').format(absen.jamAbsen)),
              _detailRow(
                'Date',
                DateFormat('dd MMM yyyy').format(absen.jamAbsen),
              ),

              // Late indicator
              if (absen.isLate) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warningOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning,
                        color: AppColors.warningOrange,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Marked as Late',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.warningOrange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    // Auto-close dialog after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _disposeAll() async {
    await _disposeControllerSafely();

    try {
      await _videoWorker?.dispose();
      _videoWorker = null;
    } catch (_) {
      // Ignore video worker disposal errors
    }

    try {
      await liveness?.dispose();
      liveness = null;
    } catch (_) {
      // Ignore liveness disposal errors
    }

    for (var t in dbTemplates) {
      try {
        t.template.dispose();
      } catch (_) {
        // Ignore template disposal errors
      }
    }
    dbTemplates.clear();

    _bannerTimer?.cancel();
  }

  Future<void> _handleExit() async {
    if (_isExiting) return;
    _isExiting = true;

    if (mounted) {
      setState(() {
        _isDisposing = true;
      });
    }

    await _disposeAll();

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _isDisposing) {
      return Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          title: const Text('Attendance Check-in'),
          backgroundColor: AppColors.primaryPurple,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Initializing camera...'),
            ],
          ),
        ),
      );
    }

    if (!controller.value.isInitialized) return Container();

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) {
          return;
        }
        await _handleExit();
      },
      child: BlocConsumer<AttendanceScanBloc, AttendanceScanState>(
        listener: (context, state) {
          if (state is AttendanceScanSuccess) {
            // Play success sound
            AudioService().playSuccessSound();
            _lastAbsenTime = state.attendance.jamAbsen;
            _lastAbsenEmployeeId = state.attendance.employeeId;
            // Show success dialog
            _showSuccessDialog(state.user, state.attendance);
            // Show top banner
            showTopBanner(
              "Attendance recorded!\n${state.user.employeeName}\n${DateFormat('HH:mm:ss').format(state.attendance.jamAbsen)}",
              color: Colors.green[700],
              seconds: 5,
            );
          } else if (state is AttendanceScanError) {
            showTopBanner(state.message, color: Colors.red[600]);
          }
        },
        builder: (context, state) {
          return Scaffold(
            backgroundColor: AppColors.backgroundLight,
            body: Stack(
              children: [
                // Camera preview with overlay
                Stack(
                  children: [
                    Center(
                      child: Padding(
                        key: _pictureKey,
                        padding: const EdgeInsets.all(1.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(0),
                          child: OverflowBox(
                            alignment: Alignment.center,
                            child: FittedBox(
                              fit: BoxFit.cover,
                              child: SizedBox(
                                width: (baseAngle == 1 || baseAngle == 2)
                                    ? controller.value.previewSize!.height
                                    : controller.value.previewSize!.width,
                                height: (baseAngle == 1 || baseAngle == 2)
                                    ? controller.value.previewSize!.width
                                    : controller.value.previewSize!.height,
                                child: CameraPreview(controller),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Subtle gradient overlay for better text contrast
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.1),
                            Colors.transparent,
                            Colors.black.withOpacity(0.3),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Bounding box & quality indicators
                if (bboxWidget != null) bboxWidget!,

                // Top notification banner
                if (_topBanner != null)
                  Positioned(
                    top: 32,
                    left: 18,
                    right: 18,
                    child: SafeArea(
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 280),
                        opacity: _topBanner != null ? 1 : 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 18,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _topBannerColor.withOpacity(0.95),
                                _topBannerColor.withOpacity(0.85),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: _topBannerColor.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _topBannerColor == Colors.green[700]
                                    ? Icons.check_circle_outline
                                    : _topBannerColor == Colors.red[600]
                                    ? Icons.error_outline
                                    : Icons.info_outline,
                                color: Colors.white,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _topBanner ?? '',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.3,
                                    height: 1.2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                // Matched user info card
                if (matchedUser != null)
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 38,
                    child: AnimatedSlide(
                      duration: const Duration(milliseconds: 400),
                      offset: matchedUser != null
                          ? Offset.zero
                          : const Offset(0, 1),
                      curve: Curves.easeOut,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withOpacity(0.8),
                              Colors.black.withOpacity(0.6),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: BackdropFilter(
                            filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 18,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.2),
                                        width: 2,
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child:
                                          matchedImage ??
                                          Container(
                                            color: Colors.white.withOpacity(
                                              0.1,
                                            ),
                                            child: const Icon(
                                              Icons.person,
                                              color: Colors.white70,
                                              size: 30,
                                            ),
                                          ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          matchedUser?.employeeId ?? '',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          matchedUser?.employeeName ?? '',
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(
                                              0.9,
                                            ),
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: AppColors.successGreen
                                                    .withOpacity(0.2),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: AppColors.successGreen
                                                      .withOpacity(0.5),
                                                  width: 1,
                                                ),
                                              ),
                                              child: Text(
                                                matchedScore?.toStringAsFixed(
                                                      3,
                                                    ) ??
                                                    '',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color:
                                                    (matchedIsReal == true
                                                            ? AppColors
                                                                  .successGreen
                                                            : AppColors
                                                                  .errorRed)
                                                        .withOpacity(0.2),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color:
                                                      (matchedIsReal == true
                                                              ? AppColors
                                                                    .successGreen
                                                              : AppColors
                                                                    .errorRed)
                                                          .withOpacity(0.5),
                                                  width: 1,
                                                ),
                                              ),
                                              child: Text(
                                                matchedIsReal == true
                                                    ? 'Real'
                                                    : 'Fake',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                // Back button
                Positioned(
                  top: 24,
                  left: 8,
                  child: SafeArea(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, size: 28),
                        color: Colors.white,
                        onPressed: _isDisposing || _isSwitching
                            ? null
                            : _handleExit,
                      ),
                    ),
                  ),
                ),

                // Bottom instruction bar
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 100,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.face,
                          color: Colors.white.withOpacity(0.8),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Position your face in the center and hold still',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            floatingActionButton: cameras.length > 1
                ? Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    child: FloatingActionButton(
                      heroTag: "btnSwitch",
                      tooltip: "Switch Camera",
                      backgroundColor: Colors.white.withOpacity(0.9),
                      foregroundColor: AppColors.primaryPurple,
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      onPressed: _isDisposing || _isSwitching
                          ? null
                          : () async {
                              await changeCamera();
                            },
                      child: const Icon(Icons.flip_camera_android, size: 24),
                    ),
                  )
                : null,
            floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    unawaited(_disposeAll());
    super.dispose();
  }
}

class _DBUserTemplate {
  final RegisteredUser user;
  final Context template;
  _DBUserTemplate({required this.user, required this.template});
}
