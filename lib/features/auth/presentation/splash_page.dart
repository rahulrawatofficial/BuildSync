import 'package:buildsync/core/config/app_setion_manager.dart';
import 'package:buildsync/features/admin/presentation/admin_dashboard.dart';
// import 'package:buildsync/features/home/presentation/home_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'login_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  User? _user;
  String? _companyId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Load session data first
    await AppSessionManager().loadSession();
    
    if (mounted) {
      setState(() {
        _user = FirebaseAuth.instance.currentUser;
        _companyId = AppSessionManager().companyId;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    print('DEBUG: SplashPage - user: ${_user?.uid}, companyId: $_companyId');
    
    if (_user != null && _companyId != null) {
      return const AdminDashboard(); // User is signed in and has company
    } else if (_user != null && _companyId == null) {
      // User is signed in but no company ID - redirect to setup
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.business, size: 64, color: Colors.blue),
              SizedBox(height: 16),
              Text(
                'Company Setup Required',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Please contact your administrator to set up your company',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    } else {
      return LoginPage(); // User not signed in
    }
  }
}
