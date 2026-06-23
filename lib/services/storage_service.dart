import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/semester.dart';
import '../models/subject.dart';
import '../models/user_profile.dart';

class StorageService {
  static const String _keyProfile = 'user_profile';
  static const String _keySemester = 'semester_v3'; // bumped: forces clean migration from old schema
  static const String _keyDarkMode = 'is_dark';

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
      return UserProfile(
        name: 'Name...',
        usn: '1BMXXCSXXX',
        priorSemesters: [
          PriorSemester(sgpa: 10.0, credits: 20),
          PriorSemester(sgpa: 10.0, credits: 20),
          PriorSemester(sgpa: 10.0, credits: 22),
        ],
      );
    }
    try {
      return UserProfile.fromJson(jsonStr);
    } catch (_) {
      return UserProfile();
    }
  }

  // Save active Semester configuration
  Future<void> saveSemester(Semester semester) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySemester, semester.toJson());
  }

  // Load active Semester configuration, returns null on first launch or corrupt data
  Future<Semester?> loadSemester() async {
    final prefs = await SharedPreferences.getInstance();
    String? jsonStr = prefs.getString(_keySemester);
    
    // --- MIGRATION: try reading from the old v2 key if v3 is missing ---
    if (jsonStr == null) {
      final oldJson = prefs.getString('semester_v2');
      if (oldJson != null) {
        try {
          final oldSem = Semester.fromJson(oldJson);
          final repaired = _repairGroupedComponents(oldSem);
          // Save to new key immediately so we don't run migration again
          await prefs.setString(_keySemester, repaired.toJson());
          return repaired;
        } catch (_) {
          // old data unreadable — fall through to return null
        }
      }
      return null;
    }
    
    try {
      final semester = Semester.fromJson(jsonStr);
      // Integrity check: grouped components must have children
      bool corrupt = false;
      for (final subject in semester.subjects) {
        for (final comp in subject.components) {
          if (comp.type == 'grouped' && comp.children.isEmpty) {
            corrupt = true;
            break;
          }
        }
        if (corrupt) break;
      }
      if (corrupt) return _repairGroupedComponents(semester);
      return semester;
    } catch (_) {
      return null;
    }
  }

  /// Repairs grouped components with missing/incorrect data by matching against
  /// the default BMSCE template. Preserves all scored marks on standalone components.
  Semester _repairGroupedComponents(Semester semester) {
    final defaultSem = Semester.defaultBMSCESem4();
    final repairedSubjects = semester.subjects.map((sub) {
      final defaultSub = defaultSem.subjects.firstWhere(
        (d) => d.code == sub.code,
        orElse: () => sub,
      );
      final repairedComponents = sub.components.map((comp) {
        if (comp.type == 'grouped') {
          // Find the matching grouped component in the default template
          final defaultComp = defaultSub.components.firstWhere(
            (d) => d.name == comp.name && d.type == 'grouped',
            orElse: () => comp,
          );
          // Repair both children (if missing) AND weight (if still at bad default of 100)
          final needsChildren = comp.children.isEmpty;
          final needsWeight = comp.weight == 100.0 && defaultComp.weight != 100.0;
          if (needsChildren || needsWeight) {
            return comp.copyWith(
              children: needsChildren ? defaultComp.children : comp.children,
              weight: needsWeight ? defaultComp.weight : comp.weight,
            );
          }
        }
        return comp;
      }).toList();
      return sub.copyWith(components: repairedComponents);
    }).toList();
    return semester.copyWith(subjects: repairedSubjects);
  }


  // Backwards compatibility wrappers
  Future<void> saveSubjects(List<Subject> subjects) async {
    final semester = await loadSemester();
    if (semester != null) {
      await saveSemester(semester.copyWith(subjects: subjects));
    } else {
      final fallback = Semester(
        name: 'BMSCE CSE Semester 4',
        totalCredits: subjects.fold(0, (sum, s) => sum + s.credits),
        subjects: subjects,
      );
      await saveSemester(fallback);
    }
  }

  Future<List<Subject>> loadSubjects() async {
    final sem = await loadSemester();
    return sem?.subjects ?? [];
  }

  Future<void> saveDarkMode(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDarkMode, isDark);
  }

  Future<bool> loadDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyDarkMode) ?? false;
  }

  // Clear all saved data (for reset feature)
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyProfile);
    await prefs.remove(_keySemester);
  }
}
