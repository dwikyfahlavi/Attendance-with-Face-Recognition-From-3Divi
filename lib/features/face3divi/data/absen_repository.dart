import '../../../models/absen_model.dart';
import 'absen_local_data_source.dart';

class AbsenRepository {
  AbsenRepository(this._dataSource);

  final AbsenLocalDataSource _dataSource;

  Stream<List<AbsenModel>> watchAbsen() => _dataSource.watchAbsen();

  // Aliases for consistency with naming conventions
  Stream<List<AbsenModel>> watchAttendance() => watchAbsen();

  Future<void> addAbsen(AbsenModel absen) => _dataSource.addAbsen(absen);

  // Alias for consistency with other naming
  Future<void> addAttendance(AbsenModel attendance) => addAbsen(attendance);

  Future<void> deleteAt(int index) => _dataSource.deleteAt(index);

  /// Get last attendance record for a user by NIK
  Future<AbsenModel?> getLastAttendanceForUser(String nik) async {
    final allAbsen = await _dataSource.getAllAbsen();
    final userAbsen = allAbsen.where((absen) => absen.nik == nik).toList();
    if (userAbsen.isEmpty) return null;
    userAbsen.sort((a, b) => b.jamAbsen.compareTo(a.jamAbsen));
    return userAbsen.first;
  }

  /// Get attendance records within a date range
  Future<List<AbsenModel>> getAttendanceByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final allAbsen = await _dataSource.getAllAbsen();

    // Normalize dates to midnight for day-level comparison
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

    final filtered = allAbsen
        .where(
          (absen) =>
              absen.jamAbsen.isAfter(start) &&
              absen.jamAbsen.isBefore(end.add(const Duration(seconds: 1))),
        )
        .toList();

    return filtered;
  }

  /// Get all attendance records
  Future<List<AbsenModel>> getAllAbsen() => _dataSource.getAllAbsen();

  // Alias for consistency with naming conventions
  Future<List<AbsenModel>> getAllAttendance() => getAllAbsen();
}
