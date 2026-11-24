import 'package:qa3ty_app/core/config/env.dart';
import 'package:qa3ty_app/core/services/locator/get_it_locator.dart';
import 'package:qa3ty_app/features/auth/data/models/user_model.dart';
import 'package:qa3ty_app/features/auth/presentation/cubits/auth_cubit.dart';

class PermissionGuard {
  PermissionGuard._();

  static AppUser? get currentUser {
    final state = ServicesLocator.authCubit.state;
    return state is Authenticated ? state.user : null;
  }

  static bool _check(bool Function(UserPermissions permissions) check) {
    final user = currentUser;
    return user == null
        ? AppConfig.current.useMockData
        : check(user.permissions);
  }

  static bool get canManageBookings =>
      _check((permissions) => permissions.canManageBookings);
  static bool get canViewReports =>
      _check((permissions) => permissions.canViewReports);
  static bool get canManageExpenses =>
      _check((permissions) => permissions.canManageExpenses);
  static bool get canManageInventory =>
      _check((permissions) => permissions.canManageInventory);
  static bool get canManageWorkers =>
      _check((permissions) => permissions.canManageWorkers);
  static bool get canManageSubAccounts => currentUser?.isPrimary ?? false;
}
