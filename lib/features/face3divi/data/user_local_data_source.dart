import 'package:hive/hive.dart';

import '../../../models/user_model.dart';

class UserLocalDataSource {
  UserLocalDataSource(this._box);

  final Box<RegisteredUser> _box;

  Stream<List<RegisteredUser>> watchUsers() async* {
    yield _box.values.toList();
    yield* _box.watch().map((_) => _box.values.toList());
  }

  List<RegisteredUser> getAllUsers() => _box.values.toList();

  bool existsByNik(String nik) => _box.values.any((u) => u.nik == nik);

  Future<void> addUser(RegisteredUser user) async {
    await _box.add(user);
  }

  Future<void> deleteAt(int index) async {
    await _box.deleteAt(index);
  }

  Future<void> updateUser(RegisteredUser user) async {
    if (user.key != null) {
      await user.save();
      return;
    }

    final existing = _box.values.cast<RegisteredUser?>().firstWhere(
      (u) => u?.nik == user.nik,
      orElse: () => null,
    );

    if (existing != null) {
      await _box.put(existing.key, user);
      return;
    }

    await _box.add(user);
  }

  Future<void> deleteUser(RegisteredUser user) async {
    await user.delete();
  }
}
