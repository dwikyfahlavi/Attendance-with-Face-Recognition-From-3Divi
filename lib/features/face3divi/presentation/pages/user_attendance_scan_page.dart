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

  DateTime? _lastAbsenTime;
  String? _lastAbsenNik;

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
          final imageBytes = user.imageBytes;
          if (!user.hasTemplate || imageBytes == null) {
            continue;
          }
          final List<RawSample> rss = await capturer.capture(imageBytes);
          if (rss.isEmpty) continue;

          Context data = service.createContextFromEncodedImage(imageBytes);
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
      // Prefer front camera
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras[camIndex],
      );

      controller = CameraController(
        frontCamera,
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

  Future<void> _safeDisposeCamera() async {
    if (_isDisposing) return;
    _isDisposing = true;
    try {
      await stopCameraStreamIfNeeded();
      if (controller.value.isInitialized) {
        await controller.dispose();
      }
    } catch (e) {
      // Ignore camera disposal errors
    }
    _isDisposing = false;
  }

  Future<void> changeCamera() async {
    if (_isSwitching || _isDisposing || cameras.length < 2) return;
    _isSwitching = true;
    try {
      await _safeDisposeCamera();
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
    if (_lastAbsenNik == user.nik && _lastAbsenTime != null) {
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
              _detailRow('NIK', user.nik),
              _detailRow('Name', user.nama),
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
    _isDisposing = true;

    await _safeDisposeCamera();

    try {
      await _videoWorker?.dispose();
    } catch (e) {
      // Ignore video worker disposal errors
    }

    try {
      await liveness?.dispose();
    } catch (e) {
      // Ignore liveness disposal errors
    }

    for (var t in dbTemplates) {
      try {
        t.template.dispose();
      } catch (e) {
        // Ignore template disposal errors
      }
    }

    _bannerTimer?.cancel();

    _isDisposing = false;
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
      canPop: !_isDisposing,
      onPopInvoked: (didPop) async {
        if (didPop && !_isDisposing) {
          await _disposeAll();
        }
      },
      child: BlocConsumer<AttendanceScanBloc, AttendanceScanState>(
        listener: (context, state) {
          if (state is AttendanceScanSuccess) {
            // Play success sound
            AudioService().playSuccessSound();
            _lastAbsenTime = state.attendance.jamAbsen;
            _lastAbsenNik = state.attendance.nik;
            // Show success dialog
            _showSuccessDialog(state.user, state.attendance);
            // Show top banner
            showTopBanner(
              "Attendance recorded!\n${state.user.nama}\n${DateFormat('HH:mm:ss').format(state.attendance.jamAbsen)}",
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
                // Camera preview
                Center(
                  child: Padding(
                    key: _pictureKey,
                    padding: const EdgeInsets.all(1.0),
                    child: CameraPreview(controller),
                  ),
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
                            vertical: 12,
                            horizontal: 16,
                          ),
                          decoration: BoxDecoration(
                            color: _topBannerColor,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: _topBannerColor.withOpacity(0.18),
                                blurRadius: 16,
                                offset: const Offset(1, 5),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _topBannerColor == Colors.green[700]
                                    ? Icons.check_circle_outline
                                    : Icons.info_outline,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _topBanner ?? '',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.3,
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
                    child: Card(
                      color: Colors.black.withOpacity(0.80),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 13,
                          horizontal: 14,
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child:
                                  matchedImage ??
                                  const SizedBox(width: 60, height: 60),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'NIK: ${matchedUser?.nik ?? ""}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Name: ${matchedUser?.nama ?? ""}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    'Score: ${matchedScore?.toStringAsFixed(3) ?? ""}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      const Text(
                                        'Status: ',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                        ),
                                      ),
                                      Text(
                                        matchedIsReal == true ? "Real" : "Fake",
                                        style: TextStyle(
                                          color: matchedIsReal == true
                                              ? Colors.green[400]
                                              : Colors.red[300],
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
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

                // Back button
                Positioned(
                  top: 24,
                  left: 8,
                  child: SafeArea(
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, size: 32),
                      color: Colors.white,
                      onPressed: _isDisposing || _isSwitching
                          ? null
                          : () async {
                              // ignore: use_build_context_synchronously
                              if (mounted) Navigator.of(context).pop();
                              await _disposeAll();
                            },
                    ),
                  ),
                ),

                // Info about loaded users
                Positioned(
                  top: 24,
                  right: 16,
                  child: SafeArea(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Users: ${dbTemplates.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            floatingActionButton: cameras.length > 1
                ? FloatingActionButton(
                    heroTag: "btnSwitch",
                    tooltip: "Switch Camera",
                    backgroundColor: AppColors.secondary,
                    onPressed: _isDisposing || _isSwitching
                        ? null
                        : () async {
                            await changeCamera();
                          },
                    child: const Icon(Icons.flip_camera_android),
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
    _isDisposing = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _disposeAll();
    });

    super.dispose();
  }
}

class _DBUserTemplate {
  final RegisteredUser user;
  final Context template;
  _DBUserTemplate({required this.user, required this.template});
}
