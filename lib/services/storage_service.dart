import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../models/semester.dart';

class StorageService {
  static const String _keyProfile = 'user_profile';
  static const String _keySemester = 'semester_v3'; // bumped: forces clean migration from old schema
  static const String _keyDarkMode = 'is_dark';
  static const String _keyHasSetTheme = 'has_user_set_theme';

  Future<void> saveUserProfile(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyProfile, profile.toJson());
  }

  Future<UserProfile?> loadUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_keyProfile);
    if (data == null) return null;
    return UserProfile.fromJson(data);
  }

  Future<void> saveSemester(Semester semester) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySemester, semester.toJson());
  }

  Future<Semester?> loadSemester() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_keySemester);
    if (data == null) return null;
    return Semester.fromJson(data);
  }

  Future<void> saveDarkMode(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDarkMode, isDark);
    await prefs.setBool(_keyHasSetTheme, true);
  }

  Future<bool> loadDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_keyHasSetTheme) != true) {
      return false;
    }
    return prefs.getBool(_keyDarkMode) ?? false;
  }

  // Clear all saved data (for reset feature)
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyProfile);
    await prefs.remove(_keySemester);
    await prefs.remove(_keyDarkMode);
    await prefs.remove(_keyHasSetTheme);
    await prefs.remove('has_shown_cgpa_alert');
  }
}
