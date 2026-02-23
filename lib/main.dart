import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:fr3divi/features/face3divi/presentation/pages/user_attendance_scan_page.dart';

import 'core/di/service_locator.dart';
import 'core/presentation/bloc/app_init_bloc.dart';
import 'core/presentation/bloc/face_sdk_bloc.dart';
import 'core/theme/app_theme.dart';
import 'data/hive_boxes.dart';
import 'core/services/logger_service.dart';
import 'features/face3divi/presentation/pages/home.dart';
import 'features/face3divi/presentation/pages/admin_auth_page.dart';
import 'features/face3divi/presentation/pages/admin_remote_login_page.dart';
import 'features/face3divi/presentation/pages/admin_dashboard_page.dart';
import 'features/face3divi/presentation/pages/admin_registration_page.dart';
import 'features/face3divi/presentation/pages/admin_members_page.dart';
import 'features/face3divi/presentation/pages/admin_member_detail_page.dart';
import 'features/face3divi/presentation/pages/admin_attendance_page.dart';
import 'features/face3divi/presentation/pages/admin_settings_page.dart';
import 'features/face3divi/presentation/pages/user_attendance_page.dart';
import 'features/face3divi/presentation/pages/attendance_history_page.dart';
import 'features/face3divi/presentation/bloc/admin_auth_bloc.dart';
import 'features/face3divi/presentation/bloc/user_list_bloc.dart';
import 'features/face3divi/presentation/bloc/admin_dashboard_bloc.dart';
import 'features/face3divi/presentation/bloc/attendance_scan_bloc.dart';
import 'features/face3divi/presentation/bloc/attendance_list_bloc.dart';
import 'features/face3divi/presentation/bloc/user_session_bloc.dart';
import 'features/face3divi/presentation/bloc/settings_bloc.dart';
import 'features/face3divi/presentation/bloc/member_detail_bloc.dart';
import 'models/user_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Hive for local storage
    await HiveBoxes.initHive();
    logger.info('Hive initialization completed', tag: 'main');

    // Initialize service locator (manual DI)
    await serviceLocator.setup();
    logger.info('Service locator setup completed', tag: 'main');

    runApp(Phoenix(child: const AttendanceApp()));

    // Lock portrait orientation
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  } catch (e, stackTrace) {
    logger.error(
      'Failed to initialize app',
      tag: 'main',
      error: e as Error?,
      stackTrace: stackTrace,
    );
    runApp(
      const MaterialApp(
        home: ErrorInitScreen(message: 'Failed to initialize application'),
      ),
    );
  }
}

/// Main app widget
class AttendanceApp extends StatefulWidget {
  const AttendanceApp({super.key});

  @override
  State<AttendanceApp> createState() => _AttendanceAppState();
}

class _AttendanceAppState extends State<AttendanceApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        logger.debug('App resumed - reinitializing Face SDK', tag: 'lifecycle');
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.inactive:
        logger.debug('App paused/detached', tag: 'lifecycle');
        break;
      case AppLifecycleState.hidden:
        logger.debug('App hidden', tag: 'lifecycle');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (_) => serviceLocator.userRepository),
        RepositoryProvider(create: (_) => serviceLocator.absenRepository),
        RepositoryProvider(create: (_) => serviceLocator.faceSdkRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) =>
                AppInitBloc(serviceLocator.cameraService)
                  ..add(InitializeAppEvent()),
          ),
          BlocProvider(
            create: (context) =>
                FaceSdkBloc(serviceLocator.faceSdkRepository)
                  ..add(InitializeFaceSdkEvent()),
          ),
          BlocProvider(create: (context) => UserSessionBloc()),
        ],
        child: MaterialApp(
          title: 'Attendance & Face Recognition System',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme(),
          home: const AppInitializer(),
          routes: _buildRoutes(),
        ),
      ),
    );
  }

  Map<String, WidgetBuilder> _buildRoutes() {
    return {
      // Admin routes - need to wrap with BLoCs
      '/admin/auth': (context) => MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => AdminAuthBloc(
              serviceLocator.userRepository,
              serviceLocator.adminPinRepository,
            ),
          ),
          BlocProvider(
            create: (context) =>
                SettingsBloc(serviceLocator.settingsRepository)
                  ..add(LoadSettingsEvent()),
          ),
        ],
        child: const AdminAuthPage(),
      ),
      '/admin/login-api': (context) => const AdminRemoteLoginPage(),
      '/admin/dashboard': (context) => MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => AdminDashboardBloc(
              serviceLocator.userRepository,
              serviceLocator.absenRepository,
            )..add(LoadDashboardEvent()),
          ),
        ],
        child: const AdminDashboardPage(),
      ),
      '/admin/members': (context) => MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => UserListBloc(serviceLocator.userRepository),
          ),
        ],
        child: const AdminMembersPage(),
      ),
      '/admin/attendance': (context) => MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) =>
                AttendanceListBloc(serviceLocator.absenRepository),
          ),
        ],
        child: const AdminAttendancePage(),
      ),
      '/admin/register': (context) => const AdminRegistrationPage(),
      '/admin/settings': (context) => MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) =>
                SettingsBloc(serviceLocator.settingsRepository)
                  ..add(LoadSettingsEvent()),
          ),
        ],
        child: const AdminSettingsPage(),
      ),
      // User routes
      '/attendance': (context) => MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => AttendanceScanBloc(
              absenRepository: serviceLocator.absenRepository,
              userRepository: serviceLocator.userRepository,
              settingsRepository: serviceLocator.settingsRepository,
              faceVerificationService: serviceLocator.faceVerificationService,
            ),
          ),
        ],
        child: const UserAttendancePage(),
      ),
      '/attendance/scan': (context) => MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => AttendanceScanBloc(
              absenRepository: serviceLocator.absenRepository,
              userRepository: serviceLocator.userRepository,
              settingsRepository: serviceLocator.settingsRepository,
              faceVerificationService: serviceLocator.faceVerificationService,
            ),
          ),
        ],
        child: const UserAttendanceScanPage(),
      ),
      '/attendance/history': (context) => MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) =>
                AttendanceListBloc(serviceLocator.absenRepository),
          ),
        ],
        child: const AttendanceHistoryPage(),
      ),
      '/admin/members/detail': (context) {
        final user =
            ModalRoute.of(context)?.settings.arguments as RegisteredUser;
        return MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (context) =>
                  MemberDetailBloc(serviceLocator.userRepository)
                    ..add(InitializeMemberDetail(user)),
            ),
          ],
          child: AdminMemberDetailPage(user: user),
        );
      },
    };
  }
}

/// Widget that handles app initialization state
class AppInitializer extends StatelessWidget {
  const AppInitializer({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppInitBloc, AppInitState>(
      builder: (context, appState) {
        if (appState.isLoading) {
          return const LoadingScreen();
        }

        if (appState.error != null) {
          return ErrorInitScreen(message: appState.error!);
        }

        return BlocBuilder<FaceSdkBloc, FaceSdkState>(
          builder: (context, sdkState) {
            if (sdkState is FaceSdkLoading) {
              return const LoadingScreen();
            }

            if (sdkState is FaceSdkError) {
              logger.error(
                'Face SDK initialization failed: ${sdkState.message}',
                tag: 'AppInitializer',
              );
              final isLicenseError = sdkState.message.contains(
                'is_accept_license',
              );
              return ErrorInitScreen(
                message: 'Face SDK Error: ${sdkState.message}',
                isLicenseError: isLicenseError,
              );
            }

            if (sdkState is FaceSdkReady) {
              logger.info(
                'App ready - Face SDK and cameras initialized',
                tag: 'AppInitializer',
              );
              return const HomePage();
            }

            return const LoadingScreen();
          },
        );
      },
    );
  }
}

/// Loading screen shown during initialization
class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF6A11CB).withOpacity(0.8),
              const Color(0xFF21D4FD).withOpacity(0.8),
            ],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              SizedBox(height: 24),
              Text(
                'Initializing...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Error screen shown during initialization failure
class ErrorInitScreen extends StatelessWidget {
  final String message;
  final bool isLicenseError;

  const ErrorInitScreen({
    super.key,
    required this.message,
    this.isLicenseError = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFEF4444).withOpacity(0.1),
              const Color(0xFFDC2626).withOpacity(0.1),
            ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 24),
                const Text(
                  'Error Initializing App',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  style: const TextStyle(fontSize: 16, color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                if (isLicenseError)
                  ElevatedButton(
                    onPressed: () {
                      SystemNavigator.pop();
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                      child: Text('Close App'),
                    ),
                  )
                else
                  ElevatedButton(
                    onPressed: () {
                      Phoenix.rebirth(context);
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                      child: Text('Retry'),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
