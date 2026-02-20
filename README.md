# FR3DiVi Attendance System

Face-recognition attendance application built with Flutter and 3DiVi Face SDK.

This project provides a role-based attendance workflow:
- **User flow**: mark attendance using camera-based face verification.
- **Admin flow**: authenticate to admin panel, register members, view attendance, and update settings.

---

## Features

- Face SDK initialization and camera lifecycle management.
- Real-time attendance scan and verification flow.
- Admin authentication with PIN support.
- Member registration and member detail pages.
- Attendance history and admin attendance monitoring.
- Local data persistence using Hive (`users`, `absen`, `admin_pins`, `settings`).
- Configurable late attendance threshold in settings.

---

## Tech Stack

- **Framework**: Flutter (Dart)
- **State Management**: BLoC (`flutter_bloc`)
- **Storage**: Hive (`hive`, `hive_flutter`)
- **Face Recognition**: local plugin `face_sdk_3divi`
- **Camera/Media**: `camera`, `audioplayers`
- **UI Utilities**: `table_calendar`, `percent_indicator`, `google_fonts`

---

## Prerequisites

Before running this project, make sure you have:

1. **Flutter SDK** compatible with Dart `^3.8.1`
2. **Android Studio** and Android toolchain
3. A **physical device** (recommended for camera + Face SDK testing)
4. 3DiVi runtime assets and license files (already included in this repository under `assets/`)

> Note: The project includes a default/demo Face SDK setup. For production licensing, use your own 3DiVi license.

---

## Quick Start

```bash
flutter pub get
flutter analyze
flutter run
```

For debug APK build:

```bash
flutter build apk --debug
```

---

## Platform Notes

### Android

This repository is already configured for Android Face SDK integration:
- Camera permission is declared in `android/app/src/main/AndroidManifest.xml`
- Native loader + method channel are implemented in `android/app/src/main/kotlin/com/example/fr3divi/MainActivity.kt`
- Native libraries are expected from `android/app/src/main/jniLibs`

### iOS

If you want to run iOS, verify additional Face SDK iOS wiring is complete (method channel + frameworks + camera/microphone permission keys).

Current `ios/Runner/Info.plist` does not yet include camera/microphone permission entries by default, so you should add them before iOS testing.

---

## Default Runtime Behavior

- A default admin PIN is initialized on first run: **`123456`**
- Default late threshold in settings: **09:00**
- App orientation is locked to portrait mode

> Recommended: change the admin PIN immediately from Admin Settings.

---

## Project Structure

```text
lib/
├── core/
│   ├── di/                  # Manual service locator
│   ├── services/            # Camera, logger, audio services
│   ├── theme/               # App colors, text styles, theme setup
│   └── presentation/bloc/   # App initialization + Face SDK blocs
├── features/face3divi/
│   ├── data/                # Data sources, repositories, face services
│   └── presentation/
│       ├── bloc/            # Feature-specific BLoCs
│       ├── pages/           # User/admin pages
│       └── widgets/         # Reusable modern UI components
├── models/                  # Hive models + adapters
└── main.dart                # App entrypoint, routes, providers
```

---

## Key Routes

- `/attendance` - User attendance flow
- `/attendance/scan` - Real-time scan page
- `/attendance/history` - Attendance history
- `/admin/auth` - Admin authentication
- `/admin/dashboard` - Admin dashboard
- `/admin/members` - Member management
- `/admin/register` - New member registration
- `/admin/attendance` - Attendance monitoring
- `/admin/settings` - System settings

---

## Development Commands

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

Clean rebuild when needed:

```bash
flutter clean
flutter pub get
```

---

## Troubleshooting

### Face SDK initialization error
- Confirm license and model assets exist under `assets/license`, `assets/conf`, and `assets/share`
- Re-run `flutter pub get` and restart the app

### Camera or scan not working
- Check app camera permission on the device
- Prefer testing on a physical device

### Build issues after dependency changes
- Run `flutter clean && flutter pub get`
- Rebuild with `flutter run` or `flutter build apk --debug`

---

## Current Status

Core architecture, BLoC migration, and main feature pages are in place. Ongoing refinement may still be needed for production hardening, test coverage, and platform-specific setup consistency.

See `PHASE_STATUS.md` for implementation progress details.

---

## Contributing

1. Create a feature branch
2. Keep changes focused and small
3. Run `flutter analyze` before opening a PR
4. Include screenshots/GIFs for UI changes where relevant

---

## License

This repository includes 3rd-party Face SDK binaries and license artifacts for local development/trial scenarios. Ensure you comply with 3DiVi licensing terms before distribution.
