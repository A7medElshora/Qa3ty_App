import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qa3ty_app/core/networking/api_exceptions.dart';
import '../../data/models/user_model.dart';
import '../../data/repos/auth_repository.dart';

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class Authenticated extends AuthState {
  final AppUser user;
  const Authenticated(this.user);
  @override
  List<Object?> get props => [user];
}

class Unauthenticated extends AuthState {
  final String? message;
  const Unauthenticated([this.message]);
  @override
  List<Object?> get props => [message];
}

class AccountSuspendedState extends AuthState {
  final String message;
  const AccountSuspendedState({required this.message});
  @override
  List<Object?> get props => [message];
}

class SubscriptionExpiredState extends AuthState {
  final String message;
  const SubscriptionExpiredState({required this.message});
  @override
  List<Object?> get props => [message];
}

class AuthErrorState extends AuthState {
  final String message;
  const AuthErrorState(this.message);
  @override
  List<Object?> get props => [message];
}

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepo;

  AuthCubit(this._authRepo) : super(AuthInitial());

  Future<void> checkAuthStatus() async {
    emit(AuthLoading());
    try {
      final hasToken = await _authRepo.hasValidToken();
      if (!hasToken) {
        emit(const Unauthenticated());
        return;
      }

      final user = await _authRepo.getCurrentUser();
      emit(Authenticated(user));
    } on ApiException catch (e) {
      if (e.code == 'account_suspended') {
        emit(AccountSuspendedState(message: e.message));
      } else if (e.code == 'subscription_expired') {
        emit(SubscriptionExpiredState(message: e.message));
      } else if (e.code == 'unauthorized' ||
          e.code == 'invalid_token' ||
          e.code == 'token_expired') {
        emit(Unauthenticated(e.message));
      } else {
        emit(AuthErrorState(e.message));
      }
    } catch (e) {
      emit(AuthErrorState(e.toString()));
    }
  }

  Future<bool> login({
    required String username,
    required String password,
  }) async {
    emit(AuthLoading());
    try {
      final session = await _authRepo.login(
        username: username,
        password: password,
      );
      emit(Authenticated(session.user));
      return true;
    } on ApiException catch (e) {
      if (e.code == 'account_suspended') {
        emit(AccountSuspendedState(message: e.message));
      } else if (e.code == 'subscription_expired') {
        emit(SubscriptionExpiredState(message: e.message));
      } else {
        emit(AuthErrorState(e.message));
      }
      return false;
    } catch (e) {
      emit(AuthErrorState(e.toString()));
      return false;
    }
  }

  Future<void> logout() async {
    emit(AuthLoading());
    await _authRepo.logout();
    emit(const Unauthenticated());
  }

  void onSessionExpired() {
    emit(const Unauthenticated(
        'انتهت صلاحية الجلسة، يرجى تسجيل الدخول مجدداً.'));
  }

  void onSubscriptionExpired(String message) {
    emit(SubscriptionExpiredState(message: message));
  }
}
