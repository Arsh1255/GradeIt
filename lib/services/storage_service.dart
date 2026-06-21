import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/subject.dart';
import '../models/subject_type.dart';
import '../models/user_profile.dart';

class StorageService {
  static const String _keyProfile = 'user_profile';
  static const String _keySubjects = 'subjects';

  // Save the user profile to local storage
  Future<void> saveUserProfile(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyProfile, profile.toJson());
  }

  // Load the user profile from local storage, returning a default one if not found
  Future<UserProfile> loadUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keyProfile);
    if (jsonStr == null) {
      // Return default profile
      return UserProfile(
        name: 'Name...',
        usn: '1BMXXCSXXX',
        sem1Sgpa: 10.0,
        sem1Credits: 20,
        sem2Sgpa: 10.0,
        sem2Credits: 20,
        sem3Sgpa: 10.0,
        sem3Credits: 22,
      );
    }
    try {
      return UserProfile.fromJson(jsonStr);
    } catch (_) {
      return UserProfile();
    }
  }

  // Save the list of subjects
  Future<void> saveSubjects(List<Subject> subjects) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = subjects.map((s) => s.toMap()).toList();
    await prefs.setString(_keySubjects, json.encode(jsonList));
  }

  Future<void> saveDarkMode(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark', isDark);
  }

  Future<bool> loadDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_dark') ?? false;
  }

  // Load the list of subjects, or initialize and return default ones
  Future<List<Subject>> loadSubjects() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keySubjects);
    if (jsonStr == null) {
      // Initialize with default Semester 4 subjects
      final defaults = _getDefaultSubjects();
      await saveSubjects(defaults);
      return defaults;
    }
    try {
      final jsonList = json.decode(jsonStr) as List<dynamic>;
      final List<Subject> loaded = jsonList.map((x) => Subject.fromMap(x)).toList();
      
      // Strict verification of official Semester 4 subject codes
      final expectedCodes = {'ADA', 'OS', 'SE', 'LAO', 'CRP', 'TFC', 'MAD', 'NPTEL'};
      final loadedCodes = loaded.map((s) => s.code).toSet();
      final hasLegacy = loadedCodes.difference(expectedCodes).isNotEmpty || loadedCodes.length != 8;
      
      if (hasLegacy) {
        final defaults = _getDefaultSubjects();
        await saveSubjects(defaults);
        return defaults;
      }
      
      // Perform inline migration for CIE max marks if they are still 40
      bool migrated = false;
      for (int i = 0; i < loaded.length; i++) {
        final sub = loaded[i];
        final updatedAssessments = sub.assessments.map((a) {
          if (a.id.startsWith('cie') && a.maxMarks == 40) {
            migrated = true;
            final double newMax = (sub.type == SubjectType.integrated) ? 10.0 : 20.0;
            double? newScored = a.scoredMarks;
            if (newScored != null) {
              newScored = (newScored / 40.0 * newMax).clamp(0.0, newMax);
            }
            double newPred = (a.predictedMarks / 40.0 * newMax).clamp(0.0, newMax);
            return a.copyWith(
              maxMarks: newMax,
              scoredMarks: newScored,
              predictedMarks: newPred,
              clearScoredMarks: newScored == null,
            );
          }
          return a;
        }).toList();
        
        if (migrated) {
          loaded[i] = sub.copyWith(assessments: updatedAssessments);
        }
      }
      
      if (migrated) {
        await saveSubjects(loaded);
      }
      
      return loaded;
    } catch (_) {
      return _getDefaultSubjects();
    }
  }

  // Clear all saved data (for reset feature)
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyProfile);
    await prefs.remove(_keySubjects);
  }

  // Helper to generate the default Semester 4 subjects
  List<Subject> _getDefaultSubjects() {
    return [
      Subject.createDefault(code: 'ADA', name: 'Analysis and Design of Algorithms', credits: 4, type: SubjectType.integrated),
      Subject.createDefault(code: 'OS', name: 'Operating Systems', credits: 4, type: SubjectType.integrated),
      Subject.createDefault(code: 'SE', name: 'Software Engineering', credits: 3, type: SubjectType.theoryA),
      Subject.createDefault(code: 'LAO', name: 'Linear Algebra and Optimization', credits: 3, type: SubjectType.theoryA),
      Subject.createDefault(code: 'CRP', name: 'Cryptography', credits: 3, type: SubjectType.theoryB),
      Subject.createDefault(code: 'TFC', name: 'Theoretical Foundations of Computation', credits: 3, type: SubjectType.theoryB),
      Subject.createDefault(code: 'MAD', name: 'Mobile Application Development', credits: 1, type: SubjectType.practical),
      Subject.createDefault(code: 'NPTEL', name: 'NPTEL Course', credits: 1, type: SubjectType.external),
    ];
  }
}
