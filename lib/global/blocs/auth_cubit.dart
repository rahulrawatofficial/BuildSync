import 'package:buildsync/features/auth/data/auth_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository repository;

  AuthCubit(this.repository) : super(AuthInitial());

  Future<void> signIn(String email, String password) async {
    try {
      emit(AuthLoading());
      await repository.signIn(email, password);
      emit(AuthSuccess());
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> signOut() async {
    await repository.signOut();
    emit(AuthInitial());
  }
}
