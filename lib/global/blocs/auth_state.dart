part of 'auth_cubit.dart';

abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthSuccess extends AuthState {
  final String uid;
  final String companyId;
  final String role;

  AuthSuccess({required this.uid, required this.companyId, required this.role});
}

class AuthFailure extends AuthState {
  final String message;
  AuthFailure(this.message);
}
