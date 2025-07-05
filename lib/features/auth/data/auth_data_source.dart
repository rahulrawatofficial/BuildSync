abstract class AuthDataSource {
  Future<void> signIn(String email, String password);
  Future<void> signOut();
  Stream<bool> authStatus(); // true if logged in
}
