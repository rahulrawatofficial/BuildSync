import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthDataSource {
  Future<User?> signIn(String email, String password);
  Future<void> signOut();
  Stream<bool> authStatus(); // true if logged in
}
