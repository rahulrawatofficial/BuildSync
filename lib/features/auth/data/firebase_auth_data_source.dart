import 'package:buildsync/core/config/app_setion_manager.dart';
import 'package:buildsync/core/utils/user_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_data_source.dart';

class FirebaseAuthDataSource implements AuthDataSource {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  FirebaseAuthDataSource(this._firebaseAuth, this._firestore);

  @override
  Future<User?> signIn(String email, String password) async {
    final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = userCredential.user;
    if (user != null) {
      // Fetch the user document
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      // Extract and store the companyId
      final companyId = userDoc.data()?['companyId'] as String?;
      print(companyId);
      if (companyId != null) {
        // Store it in memory or pass it up
        _companyId = companyId;
        await UserPreferences.saveUserData(
          companyId: userDoc.data()?['companyId'],
          name: userDoc.data()?['name'],
          email: userDoc.data()?['email'],
          phone: userDoc.data()?['phone'],
          role: userDoc.data()?['role'],
        );
      }
    }

    return userCredential.user;
  }

  String? _companyId;

  String? get currentUserUid => _firebaseAuth.currentUser?.uid;
  String? get companyId => _companyId;

  @override
  Future<void> signOut() async {
    AppSessionManager().clear();
    await UserPreferences.clearUserData();
    _companyId = null;
    await _firebaseAuth.signOut();
  }

  @override
  Stream<bool> authStatus() {
    return _firebaseAuth.authStateChanges().map((user) => user != null);
  }
}
