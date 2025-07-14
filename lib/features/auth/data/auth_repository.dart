import 'package:firebase_auth/firebase_auth.dart';

import 'auth_data_source.dart';

class AuthRepository {
  final AuthDataSource dataSource;

  AuthRepository(this.dataSource);

  Future<User?> signIn(String email, String password) =>
      dataSource.signIn(email, password);

  Future<void> signOut() => dataSource.signOut();
  Stream<bool> authStatus() => dataSource.authStatus();
}
