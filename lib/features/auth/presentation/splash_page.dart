import 'package:buildsync/core/config/app_setion_manager.dart';
import 'package:buildsync/features/admin/presentation/admin_dashboard.dart';
// import 'package:buildsync/features/home/presentation/home_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'login_page.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    final companyId = AppSessionManager().companyId;
    return FutureBuilder<User?>(
      future: Future.delayed(const Duration(milliseconds: 500), () {
        return FirebaseAuth.instance.currentUser;
      }),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        if (user != null && companyId != null) {
          return const AdminDashboard(); // User is signed in
        } else {
          return LoginPage(); // User not signed in
        }
      },
    );
  }
}
