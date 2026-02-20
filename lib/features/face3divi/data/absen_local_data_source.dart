import 'package:hive/hive.dart';

import '../../../models/absen_model.dart';

class AbsenLocalDataSource {
  AbsenLocalDataSource(this._box);

  final Box<AbsenModel> _box;

  Stream<List<AbsenModel>> watchAbsen() async* {
    yield _box.values.toList();
    yield* _box.watch().map((_) => _box.values.toList());
  }

  Future<void> addAbsen(AbsenModel absen) async {
    await _box.add(absen);
  }

  Future<void> deleteAt(int index) async {
    await _box.deleteAt(index);
  }

  /// Get all attendance records
  Future<List<AbsenModel>> getAllAbsen() async {
    return _box.values.toList();
  }
}
