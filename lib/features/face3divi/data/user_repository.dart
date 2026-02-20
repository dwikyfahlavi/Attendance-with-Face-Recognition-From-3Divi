import '../../../models/user_model.dart';
import 'user_local_data_source.dart';

class UserRepository {
  UserRepository(this._dataSource);

  final UserLocalDataSource _dataSource;

  Stream<List<RegisteredUser>> watchUsers() => _dataSource.watchUsers();

  List<RegisteredUser> getAllUsers() => _dataSource.getAllUsers();

  bool existsByNik(String nik) => _dataSource.existsByNik(nik);

  Future<void> addUser(RegisteredUser user) => _dataSource.addUser(user);

  Future<void> deleteAt(int index) => _dataSource.deleteAt(index);

  Future<void> updateUser(RegisteredUser user) => _dataSource.updateUser(user);

  Future<void> deleteUser(RegisteredUser user) => _dataSource.deleteUser(user);

  /// Add or update user - updates if exists by NIK, otherwise adds new user
  Future<void> addOrUpdateUser(RegisteredUser user) async {
    if (existsByNik(user.nik)) {
      await updateUser(user);
    } else {
      await addUser(user);
    }
  }

  /// Get user by NIK (ID)
  RegisteredUser? getUserByNik(String nik) {
    final users = getAllUsers();
    try {
      return users.firstWhere((user) => user.nik == nik);
    } catch (e) {
      return null;
    }
  }

  /// Get user by NIK and check if admin
  Future<bool> isUserAdmin(String nik) async {
    final user = getUserByNik(nik);
    return user != null && user.isAdmin;
  }
}
