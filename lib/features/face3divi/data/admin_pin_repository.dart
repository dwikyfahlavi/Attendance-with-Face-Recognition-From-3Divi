import 'package:hive/hive.dart';
import 'package:crypto/crypto.dart';
import '../../../models/admin_pin_model.dart';

class AdminPinRepository {
  final Box<AdminPinModel> _adminPinBox;
  static const String _pinKey = 'current_pin';
  static const String _defaultPin = '123456'; // Default PIN

  AdminPinRepository(this._adminPinBox);

  /// Initialize with default PIN if no PIN exists
  Future<void> initializeDefaultPin() async {
    try {
      final existing = _adminPinBox.get(_pinKey);
      if (existing == null) {
        await setPIN(_defaultPin, 'System');
      }
    } catch (e) {
      throw Exception('Failed to initialize PIN: $e');
    }
  }

  /// Set a new PIN (hashed)
  Future<void> setPIN(String pin, String setBy) async {
    try {
      final pinHash = sha256.convert(pin.codeUnits).toString();
      final model = AdminPinModel(
        pinHash: pinHash,
        createdAt: DateTime.now(),
        createdBy: setBy,
      );
      await _adminPinBox.put(_pinKey, model);
    } catch (e) {
      throw Exception('Failed to set PIN: $e');
    }
  }

  /// Verify if the provided PIN is correct
  Future<bool> verifyPIN(String pin) async {
    try {
      final stored = _adminPinBox.get(_pinKey);
      if (stored == null) {
        return false;
      }
      final pinHash = sha256.convert(pin.codeUnits).toString();
      return stored.pinHash == pinHash;
    } catch (e) {
      throw Exception('Failed to verify PIN: $e');
    }
  }

  /// Update PIN (requires current PIN verification)
  Future<void> updatePIN({
    required String currentPin,
    required String newPin,
    String? updatedBy,
  }) async {
    try {
      // Verify current PIN
      final isValid = await verifyPIN(currentPin);
      if (!isValid) {
        throw Exception('Current PIN is incorrect');
      }

      // Set new PIN
      await setPIN(newPin, updatedBy ?? 'Admin');
    } catch (e) {
      throw Exception('Failed to update PIN: $e');
    }
  }

  /// Get PIN creation info
  Future<AdminPinModel?> getPINInfo() async {
    try {
      return _adminPinBox.get(_pinKey);
    } catch (e) {
      return null;
    }
  }
}
