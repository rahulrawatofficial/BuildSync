import 'package:buildsync/features/auth/data/auth_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository repository;

  AuthCubit(this.repository) : super(AuthInitial());

  Future<void> signIn(String email, String password) async {
    try {
      emit(AuthLoading());

      // Step 1: Sign in
      final user = await repository.signIn(email, password);
      final uid = user?.uid;

      if (uid == null) {
        emit(AuthFailure("UID is null"));
        return;
      }

      // Step 2: Find company ID
      final companyId = await _findCompanyIdForUser(uid);
      if (companyId == null) {
        emit(AuthFailure("Company not found for user"));
        return;
      }

      // Step 3: Fetch role
      final userDoc =
          await FirebaseFirestore.instance
              .collection('companies')
              .doc(companyId)
              .collection('users')
              .doc(uid)
              .get();

      if (!userDoc.exists) {
        emit(AuthFailure("User profile not found"));
        return;
      }

      final role = userDoc['role'];

      // Step 4: Emit success with user data
      emit(AuthSuccess(uid: uid, companyId: companyId, role: role));
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> signOut() async {
    await repository.signOut();
    emit(AuthInitial());
  }

  // Helper function
  Future<String?> _findCompanyIdForUser(String uid) async {
    final companies =
        await FirebaseFirestore.instance.collection('companies').get();
    for (final company in companies.docs) {
      final userDoc =
          await company.reference.collection('users').doc(uid).get();
      if (userDoc.exists) return company.id;
    }
    return null;
  }
}
