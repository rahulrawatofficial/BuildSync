import 'package:shared_preferences/shared_preferences.dart';

class AppSessionManager {
  static final AppSessionManager _instance = AppSessionManager._internal();
  factory AppSessionManager() => _instance;
  AppSessionManager._internal();

  String? companyId;
  String? name;
  String? email;
  String? role;

  Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    companyId = prefs.getString('companyId');
    name = prefs.getString('name');
    email = prefs.getString('email');
    role = prefs.getString('role');
  }

  void clear() {
    companyId = null;
    name = null;
    email = null;
    role = null;
  }
}
