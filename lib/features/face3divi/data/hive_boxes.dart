import 'package:hive_flutter/hive_flutter.dart';
import 'models/user_model.dart';
import 'models/absen_model.dart';
import 'models/admin_pin_model.dart';
import 'models/settings_model.dart';

class HiveBoxes {
  static const String userBoxName = 'users';
  static const String absenBoxName = 'absen';
  static const String adminPinBoxName = 'admin_pins';
  static const String settingsBoxName = 'settings';

  static Future<void> initHive() async {
    await Hive.initFlutter();

    // Register adapters
    Hive.registerAdapter(RegisteredUserAdapter());
    Hive.registerAdapter(AbsenModelAdapter());
    Hive.registerAdapter(AdminPinModelAdapter());
    Hive.registerAdapter(SettingsModelAdapter());

    // Open boxes
    await Hive.openBox<RegisteredUser>(userBoxName);

    // Open absen box with migration handling
    try {
      await Hive.openBox<AbsenModel>(absenBoxName);
    } catch (e) {
      // If opening fails (e.g., due to schema change), delete and reopen
      await Hive.deleteBoxFromDisk(absenBoxName);
      await Hive.openBox<AbsenModel>(absenBoxName);
    }

    await Hive.openBox<AdminPinModel>(adminPinBoxName);

    // Open settings box with migration handling
    try {
      await Hive.openBox<SettingsModel>(settingsBoxName);
    } catch (e) {
      // If opening fails (e.g., due to schema change), delete and reopen
      await Hive.deleteBoxFromDisk(settingsBoxName);
      await Hive.openBox<SettingsModel>(settingsBoxName);
    }
  }

  static Box<RegisteredUser> get userBox =>
      Hive.box<RegisteredUser>(userBoxName);

  static Box<AbsenModel> get absenBox => Hive.box<AbsenModel>(absenBoxName);

  static Box<AdminPinModel> get adminPinBox =>
      Hive.box<AdminPinModel>(adminPinBoxName);

  static Box<SettingsModel> get settingsBox =>
      Hive.box<SettingsModel>(settingsBoxName);

  /// Clear all data - useful for fresh start
  static Future<void> clearAllBoxes() async {
    await userBox.clear();
    await absenBox.clear();
    await adminPinBox.clear();
    await settingsBox.clear();
  }
}
