import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/user_repository.dart';
import '../../data/absen_repository.dart';

// Events
abstract class AdminDashboardEvent {}

class LoadDashboardEvent extends AdminDashboardEvent {}

class RefreshDashboardEvent extends AdminDashboardEvent {}

// States
abstract class AdminDashboardState {
  const AdminDashboardState();
}

class AdminDashboardInitial extends AdminDashboardState {
  const AdminDashboardInitial();
}

class AdminDashboardLoading extends AdminDashboardState {
  const AdminDashboardLoading();
}

class AdminDashboardLoaded extends AdminDashboardState {
  final int totalMembers;
  final int presentToday;
  final int absentToday;

  const AdminDashboardLoaded({
    required this.totalMembers,
    required this.presentToday,
    required this.absentToday,
  });
}

class AdminDashboardError extends AdminDashboardState {
  final String message;
  const AdminDashboardError(this.message);
}

// BLoC
class AdminDashboardBloc
    extends Bloc<AdminDashboardEvent, AdminDashboardState> {
  final UserRepository _userRepository;
  final AbsenRepository _absenRepository;

  AdminDashboardBloc(this._userRepository, this._absenRepository)
    : super(const AdminDashboardInitial()) {
    on<LoadDashboardEvent>(_onLoadDashboard);
    on<RefreshDashboardEvent>(_onRefreshDashboard);
  }

  Future<void> _onLoadDashboard(
    LoadDashboardEvent event,
    Emitter<AdminDashboardState> emit,
  ) async {
    try {
      emit(const AdminDashboardLoading());
      await _loadAndEmitDashboardData(emit);
    } catch (e) {
      emit(AdminDashboardError(e.toString()));
    }
  }

  Future<void> _onRefreshDashboard(
    RefreshDashboardEvent event,
    Emitter<AdminDashboardState> emit,
  ) async {
    try {
      await _loadAndEmitDashboardData(emit);
    } catch (e) {
      emit(AdminDashboardError(e.toString()));
    }
  }

  Future<void> _loadAndEmitDashboardData(
    Emitter<AdminDashboardState> emit,
  ) async {
    // Get total members (excluding admins)
    final users = _userRepository.getAllUsers();
    final totalMembers = users.where((user) => !user.isAdmin).length;

    // Get today's date (without time)
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayEnd = DateTime(today.year, today.month, today.day, 23, 59, 59);

    // Get attendance records for today
    final allAttendance = await _absenRepository.getAllAttendance();
    final todayAttendance = allAttendance
        .where(
          (record) =>
              record.jamAbsen.isAfter(todayStart) &&
              record.jamAbsen.isBefore(todayEnd),
        )
        .toList();

    // Count unique users who attended today
    final uniqueNiksPresent = <String>{};
    for (var record in todayAttendance) {
      uniqueNiksPresent.add(record.nik);
    }
    final presentToday = uniqueNiksPresent.length;

    // Calculate absent
    final absentToday = totalMembers - presentToday;

    emit(
      AdminDashboardLoaded(
        totalMembers: totalMembers,
        presentToday: presentToday,
        absentToday: absentToday,
      ),
    );
  }
}
