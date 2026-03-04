import '../../../models/user_model.dart';
import 'user_local_data_source.dart';

class UserRepository {
  UserRepository(this._dataSource);

  final UserLocalDataSource _dataSource;

  Stream<List<RegisteredUser>> watchUsers() => _dataSource.watchUsers();

  List<RegisteredUser> getAllUsers() => _dataSource.getAllUsers();

  bool existsByEmployeeId(String employeeId) =>
      _dataSource.existsByEmployeeId(employeeId);

  Future<void> addUser(RegisteredUser user) => _dataSource.addUser(user);

  Future<void> deleteAt(int index) => _dataSource.deleteAt(index);

  Future<void> updateUser(RegisteredUser user) => _dataSource.updateUser(user);

  Future<void> deleteUser(RegisteredUser user) => _dataSource.deleteUser(user);

  /// Add or update user - updates if exists by employee ID, otherwise adds new user
  Future<void> addOrUpdateUser(RegisteredUser user) async {
    if (existsByEmployeeId(user.employeeId)) {
      await updateUser(user);
    } else {
      await addUser(user);
    }
  }

  /// Get user by employee ID
  RegisteredUser? getUserByEmployeeId(String employeeId) {
    final users = getAllUsers();
    try {
      return users.firstWhere((user) => user.employeeId == employeeId);
    } catch (e) {
      return null;
    }
  }

  /// Get user by employee ID and check if admin
  Future<bool> isUserAdmin(String employeeId) async {
    final user = getUserByEmployeeId(employeeId);
    return user != null && user.isAdmin;
  }
}
