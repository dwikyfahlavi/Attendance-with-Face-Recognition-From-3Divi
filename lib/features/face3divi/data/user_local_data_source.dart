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
    await user.save();
  }

  Future<void> deleteUser(RegisteredUser user) async {
    await user.delete();
  }
}
