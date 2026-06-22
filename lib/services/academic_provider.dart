import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../models/subject.dart';
import '../models/generic_component.dart';
import '../models/user_profile.dart';
import '../models/grade_scheme.dart';
import '../models/semester.dart';
import '../core/grading_calculator.dart';
import 'storage_service.dart';

class AcademicProvider with ChangeNotifier {
  final StorageService _storageService = StorageService();
  
  Semester? _semester;
  UserProfile _userProfile = UserProfile();
  List<String> _activities = [];
  bool _isLoading = true;
  bool _isDarkMode = false;

  // --- CONFIGURATION MODE PROPERTIES ---
  bool _isConfigMode = false;
  Semester? _draftSemester;

  bool get isConfigMode => _isConfigMode;
  Semester? get draftSemester => _draftSemester;

  bool get hasConfiguredSemester => semester != null;
  Semester? get semester => _isConfigMode ? _draftSemester : _semester;
  List<Subject> get subjects => semester?.subjects ?? [];
  UserProfile get userProfile => _userProfile;
  List<String> get activities => _activities;
  bool get isLoading => _isLoading;
  bool get isDarkMode => _isDarkMode;
  GradeScheme get gradeScheme => semester?.gradeScheme ?? GradeScheme.defaultBMSCE;

  void enterConfigurationMode() {
    if (_semester == null) return;
    _draftSemester = Semester.fromJson(json.encode(_semester!.toMap()));
    _isConfigMode = true;
    _logActivity('Entered Semester Configuration Mode (draft editing)');
    notifyListeners();
  }

  void cancelConfigurationMode() {
    _isConfigMode = false;
    _draftSemester = null;
    _logActivity('Exited Semester Configuration Mode without saving');
    notifyListeners();
  }

  // Validates a semester model and returns a list of error strings
  List<String> validateSemester(Semester sem) {
    final List<String> errors = [];

    // 1. Metadata check
    if (sem.name.trim().isEmpty) {
      errors.add("Semester name cannot be empty.");
    }

    // 2. Subject credits equal total semester credits
    final sumSubjectCredits = sem.subjects.fold<int>(0, (sum, s) => sum + s.credits);
    if (sumSubjectCredits != sem.totalCredits) {
      errors.add("Total of subject credits ($sumSubjectCredits) must equal the configured semester credits (${sem.totalCredits}).");
    }

    // 3. Subject validation
    if (sem.subjects.isEmpty) {
      errors.add("The semester must have at least one subject.");
    }

    for (final subject in sem.subjects) {
      final subLabel = "${subject.name} (${subject.code})";
      if (subject.code.trim().isEmpty) {
        errors.add("Subject code cannot be empty.");
      }
      if (subject.name.trim().isEmpty) {
        errors.add("Subject name cannot be empty.");
      }
      if (subject.credits <= 0) {
        errors.add("$subLabel: Credits must be greater than 0.");
      }

      // Subject contains components
      if (subject.components.isEmpty) {
        errors.add("$subLabel: Subject must contain at least one assessment component.");
        continue;
      }

      // Component checks
      List<String> validateComponents(List<GenericComponent> list, String parentPath) {
        final List<String> compErrors = [];
        for (final c in list) {
          if (c.name.trim().isEmpty) {
            compErrors.add("$parentPath: Component name cannot be empty.");
          }
          if (c.type == 'standalone') {
            if (c.maxMarks <= 0) {
              compErrors.add("$parentPath -> ${c.name}: Max marks must be greater than 0.");
            }
            if (c.weight < 0) {
              compErrors.add("$parentPath -> ${c.name}: Weight cannot be negative.");
            }
          } else if (c.type == 'grouped') {
            if (c.selectionRule.trim().isEmpty) {
              compErrors.add("$parentPath -> ${c.name}: Grouped component must have a selection rule.");
            }
            if (c.children.isEmpty) {
              compErrors.add("$parentPath -> ${c.name}: Grouped component must have at least one child component.");
            } else {
              compErrors.addAll(validateComponents(c.children, "$parentPath -> ${c.name}"));
            }
          }
        }
        return compErrors;
      }

      errors.addAll(validateComponents(subject.components, subLabel));

      final totalWeight = subject.components.fold(0.0, (s, c) => s + c.weight);
      if ((totalWeight - 100.0).abs() > 0.001) {
        errors.add("$subLabel: Assessment component weights must sum to exactly 100 (current: ${totalWeight.toStringAsFixed(1)}).");
      }
    }

    // 4. Grade scheme validation
    final scheme = sem.gradeScheme;
    if (scheme.boundaries.isEmpty) {
      errors.add("Grade scheme must contain at least one grade boundary.");
    } else {
      final sortedBoundaries = List<GradeBoundary>.from(scheme.boundaries)
        ..sort((a, b) => a.minMarks.compareTo(b.minMarks));

      // Overlaps and gaps validation
      for (int i = 0; i < sortedBoundaries.length; i++) {
        final b = sortedBoundaries[i];
        if (b.minMarks < 0 || b.minMarks > 100) {
          errors.add("Grade boundary ${b.gradeLetter} has invalid marks: ${b.minMarks}. Must be between 0 and 100.");
        }
        if (b.gradePoints < 0 || b.gradePoints > 10) {
          errors.add("Grade boundary ${b.gradeLetter} has invalid grade points: ${b.gradePoints}. Must be between 0 and 10.");
        }
        if (i > 0) {
          final prev = sortedBoundaries[i - 1];
          if (b.minMarks == prev.minMarks) {
            errors.add("Overlapping grade boundary: Multiple grades defined for ${b.minMarks} marks.");
          }
          if (b.gradeLetter == prev.gradeLetter) {
            errors.add("Duplicate grade letter: '${b.gradeLetter}' is defined multiple times.");
          }
        }
      }
      
      // Ensure there is a baseline grade (typically F/Fail) covering marks starting at 0
      final hasZeroBaseline = sortedBoundaries.any((b) => b.minMarks == 0);
      if (!hasZeroBaseline) {
        errors.add("Grade mapping gap: There must be a grade boundary starting at 0 marks (e.g. F grade).");
      }
    }

    return errors;
  }

  List<String> saveConfigurationMode() {
    if (_draftSemester == null) return ['No active draft configuration.'];
    
    final validationErrors = validateSemester(_draftSemester!);
    if (validationErrors.isNotEmpty) {
      return validationErrors;
    }
    
    _semester = _draftSemester;
    _storageService.saveSemester(_semester!);
    _isConfigMode = false;
    _draftSemester = null;
    _logActivity('Semester configuration saved and locked');
    notifyListeners();
    return [];
  }

  void _updateActiveSemester(Semester updatedSem) {
    if (_isConfigMode) {
      _draftSemester = updatedSem;
    } else {
      _semester = updatedSem;
      _storageService.saveSemester(_semester!);
    }
    notifyListeners();
  }

  void updateGradeScheme(GradeScheme scheme) {
    final sem = semester;
    if (sem != null) {
      final updated = sem.copyWith(gradeScheme: scheme);
      _updateActiveSemester(updated);
      _logActivity('Grading boundaries scheme updated.');
    }
  }

  Future<void> toggleDarkMode() async {
    _isDarkMode = !_isDarkMode;
    await _storageService.saveDarkMode(_isDarkMode);
    notifyListeners();
  }

  AcademicProvider() {
    _init();
  }

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();

    _userProfile = await _storageService.loadUserProfile() ?? UserProfile();
    _semester = await _storageService.loadSemester();
    _isDarkMode = await _storageService.loadDarkMode();
    
    if (_semester != null) {
      _activities = [
        'Welcome back to GradeIt! "${_semester!.name}" loaded.',
        'Active subjects: ${_semester!.subjects.map((s) => s.code).join(", ")}.',
      ];
    } else {
      _activities = [
        'Welcome to GradeIt! Setup a semester to begin.',
      ];
    }
    
    _isLoading = false;
    notifyListeners();
  }

  // --- MUTATORS ---

  Future<void> useDefaultTemplate() async {
    _semester = Semester.defaultBMSCESem4();
    await _storageService.saveSemester(_semester!);
    _logActivity('Initialized built-in template: BMSCE CSE Semester 4');
    notifyListeners();
  }

  Future<void> createCustomSemester(Semester newSemester) async {
    _semester = newSemester;
    await _storageService.saveSemester(_semester!);
    _logActivity('Configured custom semester: "${newSemester.name}"');
    notifyListeners();
  }

  Future<void> updateUserProfile(UserProfile profile) async {
    _userProfile = profile;
    await _storageService.saveUserProfile(profile);
    _logActivity('Academic history updated (${profile.priorSemesters.length} prior semesters)');
    notifyListeners();
  }

  // Recursive helper to update nested component values
  List<GenericComponent> _updateComponentRecursive(
    List<GenericComponent> comps,
    String id,
    double? scoredMarks,
    double predictedMarks,
    bool isCompleted,
  ) {
    return comps.map((c) {
      if (c.id == id) {
        return c.copyWith(
          scoredMarks: scoredMarks,
          predictedMarks: predictedMarks,
          isCompleted: isCompleted,
          clearScoredMarks: !isCompleted,
        );
      } else if (c.type == 'grouped') {
        return c.copyWith(
          children: _updateComponentRecursive(c.children, id, scoredMarks, predictedMarks, isCompleted),
        );
      }
      return c;
    }).toList();
  }

  Future<void> updateAssessment({
    required String subjectCode,
    required String assessmentId,
    double? scoredMarks,
    required double predictedMarks,
    required bool isCompleted,
    bool saveToDisk = true,
  }) async {
    final sem = semester;
    if (sem == null) return;
    final subIndex = sem.subjects.indexWhere((s) => s.code == subjectCode);
    if (subIndex == -1) return;

    final subject = sem.subjects[subIndex];
    
    GenericComponent? findComponent(List<GenericComponent> list) {
      for (final c in list) {
        if (c.id == assessmentId) return c;
        if (c.type == 'grouped') {
          final found = findComponent(c.children);
          if (found != null) return found;
        }
      }
      return null;
    }

    final oldComponent = findComponent(subject.components);
    if (oldComponent == null) return;

    String logMsg = '';
    if (saveToDisk) {
      if (isCompleted && !oldComponent.isCompleted) {
        logMsg = 'Completed ${subject.name} - ${oldComponent.name}: Scored $scoredMarks/${oldComponent.maxMarks}';
      } else if (isCompleted && oldComponent.isCompleted && oldComponent.scoredMarks != scoredMarks) {
        logMsg = 'Corrected ${subject.name} - ${oldComponent.name} marks to $scoredMarks/${oldComponent.maxMarks}';
      } else if (!isCompleted && oldComponent.isCompleted) {
        logMsg = 'Set ${subject.name} - ${oldComponent.name} back to pending';
      } else if (oldComponent.predictedMarks != predictedMarks) {
        logMsg = 'Adjusted prediction for ${subject.name} - ${oldComponent.name} to $predictedMarks/${oldComponent.maxMarks}';
      }
    }

    final updatedComponents = _updateComponentRecursive(
      subject.components,
      assessmentId,
      scoredMarks,
      predictedMarks,
      isCompleted,
    );

    final updatedSubjects = List<Subject>.from(sem.subjects);
    updatedSubjects[subIndex] = subject.copyWith(components: updatedComponents);

    final updatedSem = sem.copyWith(subjects: updatedSubjects);
    _updateActiveSemester(updatedSem);
    if (saveToDisk && logMsg.isNotEmpty) {
      _logActivity(logMsg);
    }
  }

  // --- GENERIC COMPONENT CRUD METHODS ---

  Future<void> addComponent(String subjectCode, GenericComponent component) async {
    final sem = semester;
    if (sem == null) return;
    final subIndex = sem.subjects.indexWhere((s) => s.code == subjectCode);
    if (subIndex == -1) return;
    
    final subject = sem.subjects[subIndex];
    final updatedComponents = List<GenericComponent>.from(subject.components)..add(component);
    final updatedSubject = subject.copyWith(components: updatedComponents);
    
    final updatedSubjects = List<Subject>.from(sem.subjects);
    updatedSubjects[subIndex] = updatedSubject;
    
    final updatedSem = sem.copyWith(subjects: updatedSubjects);
    _updateActiveSemester(updatedSem);
    _logActivity('Added component "${component.name}" to subject ${subject.code}');
  }

  Future<void> updateComponent(String subjectCode, GenericComponent component) async {
    final sem = semester;
    if (sem == null) return;
    final subIndex = sem.subjects.indexWhere((s) => s.code == subjectCode);
    if (subIndex == -1) return;
    
    final subject = sem.subjects[subIndex];
    
    List<GenericComponent> updateInList(List<GenericComponent> list) {
      return list.map((c) {
        if (c.id == component.id) {
          return component;
        } else if (c.type == 'grouped') {
          return c.copyWith(children: updateInList(c.children));
        }
        return c;
      }).toList();
    }

    final updatedComponents = updateInList(subject.components);
    final updatedSubject = subject.copyWith(components: updatedComponents);
    
    final updatedSubjects = List<Subject>.from(sem.subjects);
    updatedSubjects[subIndex] = updatedSubject;
    
    final updatedSem = sem.copyWith(subjects: updatedSubjects);
    _updateActiveSemester(updatedSem);
    _logActivity('Updated component "${component.name}" in subject ${subject.code}');
  }

  Future<void> deleteComponent(String subjectCode, String componentId) async {
    final sem = semester;
    if (sem == null) return;
    final subIndex = sem.subjects.indexWhere((s) => s.code == subjectCode);
    if (subIndex == -1) return;
    
    final subject = sem.subjects[subIndex];
    
    List<GenericComponent> deleteFromList(List<GenericComponent> list) {
      final filtered = list.where((c) => c.id != componentId).toList();
      return filtered.map((c) {
        if (c.type == 'grouped') {
          return c.copyWith(children: deleteFromList(c.children));
        }
        return c;
      }).toList();
    }

    final updatedComponents = deleteFromList(subject.components);
    final updatedSubject = subject.copyWith(components: updatedComponents);
    
    final updatedSubjects = List<Subject>.from(sem.subjects);
    updatedSubjects[subIndex] = updatedSubject;
    
    final updatedSem = sem.copyWith(subjects: updatedSubjects);
    _updateActiveSemester(updatedSem);
    _logActivity('Deleted component with ID "$componentId" from subject ${subject.code}');
  }

  Future<void> reorderComponents(String subjectCode, int oldIndex, int newIndex) async {
    final sem = semester;
    if (sem == null) return;
    final subIndex = sem.subjects.indexWhere((s) => s.code == subjectCode);
    if (subIndex == -1) return;
    
    final subject = sem.subjects[subIndex];
    final list = List<GenericComponent>.from(subject.components);
    
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    
    final updatedSubject = subject.copyWith(components: list);
    final updatedSubjects = List<Subject>.from(sem.subjects);
    updatedSubjects[subIndex] = updatedSubject;
    
    final updatedSem = sem.copyWith(subjects: updatedSubjects);
    _updateActiveSemester(updatedSem);
  }

  // --- SUBJECT CRUD METHODS FOR CONFIGURATION MODE ---

  void addSubject(Subject subject) {
    final sem = semester;
    if (sem == null) return;
    final updatedSubjects = List<Subject>.from(sem.subjects)..add(subject);
    final updatedSem = sem.copyWith(subjects: updatedSubjects);
    _updateActiveSemester(updatedSem);
    _logActivity('Added subject "${subject.name}" (${subject.code})');
  }

  void updateSubject(String oldCode, Subject updatedSubject) {
    final sem = semester;
    if (sem == null) return;
    final index = sem.subjects.indexWhere((s) => s.code == oldCode);
    if (index == -1) return;
    
    final updatedSubjects = List<Subject>.from(sem.subjects);
    updatedSubjects[index] = updatedSubject;
    
    final updatedSem = sem.copyWith(subjects: updatedSubjects);
    _updateActiveSemester(updatedSem);
    _logActivity('Updated subject "${updatedSubject.name}"');
  }

  void deleteSubject(String code) {
    final sem = semester;
    if (sem == null) return;
    final updatedSubjects = sem.subjects.where((s) => s.code != code).toList();
    final updatedSem = sem.copyWith(subjects: updatedSubjects);
    _updateActiveSemester(updatedSem);
    _logActivity('Deleted subject with code "$code"');
  }

  void reorderSubjects(int oldIndex, int newIndex) {
    final sem = semester;
    if (sem == null) return;
    final list = List<Subject>.from(sem.subjects);
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    
    final updatedSem = sem.copyWith(subjects: list);
    _updateActiveSemester(updatedSem);
  }

  void updateDraftSemesterMetadata({required String name, String? college, String? branch, required int totalCredits}) {
    final sem = semester;
    if (sem == null) return;
    final updatedSem = sem.copyWith(
      name: name,
      collegeName: college,
      branchName: branch,
      totalCredits: totalCredits,
    );
    _updateActiveSemester(updatedSem);
    _logActivity('Updated semester metadata');
  }

  Future<void> resetAll() async {
    await _storageService.clearAll();
    _semester = null;
    _draftSemester = null;
    _isConfigMode = false;
    await _init();
    _logActivity('System reset. All academic metrics cleared.');
  }

  void _logActivity(String activity) {
    _activities.insert(0, '[${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}] $activity');
    if (_activities.length > 30) {
      _activities.removeLast();
    }
  }

  // --- DERIVED METRICS ---

  int get sem4TotalCredits => _semester?.totalCredits ?? subjects.fold(0, (sum, s) => sum + s.credits);

  double get currentSgpa => _semester?.calculateSgpa(usePredictions: false) ?? 0.0;
  double get predictedSgpa => _semester?.calculateSgpa(usePredictions: true) ?? 0.0;
  double get maxSgpa => _semester?.calculateSgpa(useMaxPending: true) ?? 0.0;
  double get minSgpa => _semester?.calculateSgpa(useMinPending: true) ?? 0.0;

  double get currentCgpa => GradingCalculator.calculateCgpa(
        profile: _userProfile,
        sem4Sgpa: currentSgpa,
        sem4Credits: sem4TotalCredits,
      );

  double get predictedCgpa => GradingCalculator.calculateCgpa(
        profile: _userProfile,
        sem4Sgpa: predictedSgpa,
        sem4Credits: sem4TotalCredits,
      );

  double get maxCgpa => GradingCalculator.calculateCgpa(
        profile: _userProfile,
        sem4Sgpa: maxSgpa,
        sem4Credits: sem4TotalCredits,
      );

  double get minCgpa => GradingCalculator.calculateCgpa(
        profile: _userProfile,
        sem4Sgpa: minSgpa,
        sem4Credits: sem4TotalCredits,
      );

  double get totalScoredMarks => subjects.fold(0.0, (sum, s) => sum + s.currentScore);
  double get totalPredictedMarks => subjects.fold(0.0, (sum, s) => sum + s.predictedScore);
  double get totalMaxMarksPossible => subjects.fold(0.0, (sum, s) => sum + s.maxPossibleScore);
  double get totalMarksLost => subjects.fold(0.0, (sum, s) => sum + s.marksPermanentlyLost);
  double get totalRemainingAchievable => subjects.fold(0.0, (sum, s) => sum + s.remainingAchievableMarks);

  double get semesterCompletionPercentage {
    if (subjects.isEmpty) return 0.0;
    
    int countComponents(List<GenericComponent> list) {
      int count = 0;
      for (final c in list) {
        if (c.type == 'standalone') {
          count++;
        } else {
          count += countComponents(c.children);
        }
      }
      return count;
    }
    
    int countCompleted(List<GenericComponent> list) {
      int count = 0;
      for (final c in list) {
        if (c.type == 'standalone') {
          if (c.isCompleted) count++;
        } else {
          count += countCompleted(c.children);
        }
      }
      return count;
    }

    int totalComponents = 0;
    int completedComponents = 0;
    for (final s in subjects) {
      totalComponents += countComponents(s.components);
      completedComponents += countCompleted(s.components);
    }
    
    if (totalComponents == 0) return 0.0;
    return (completedComponents / totalComponents) * 100;
  }

  // --- RULE-BASED DYNAMIC INSIGHT ENGINE ---
  
  List<String> get academicInsights {
    final List<String> insights = [];

    if (subjects.isEmpty) return ['Loading academic analytics...'];

    final double predSgpa = predictedSgpa;
    if (predSgpa >= 9.5) {
      insights.add('🏆 Exceptional Performance! Your predicted SGPA of ${predSgpa.toStringAsFixed(2)} places you in the top tier. Keep executing at this level.');
    } else if (predSgpa >= 8.5) {
      insights.add('🌟 Strong Standing. Your predicted SGPA is ${predSgpa.toStringAsFixed(2)}. A slight push in your upcoming final exams could elevate you above 9.0.');
    } else if (predSgpa >= 7.0) {
      insights.add('📈 Solid progress. You are on track for a ${predSgpa.toStringAsFixed(2)} SGPA. Identify subjects with lost marks to prioritize your study hours.');
    } else {
      insights.add('⚠️ Attention Required. Predicted SGPA is ${predSgpa.toStringAsFixed(2)}. Focus on securing full internal marks to establish a safe baseline before final exams.');
    }

    final sortedByLost = List<Subject>.from(subjects)
      ..sort((a, b) => b.marksPermanentlyLost.compareTo(a.marksPermanentlyLost));
    final highestLostSub = sortedByLost.first;

    if (highestLostSub.marksPermanentlyLost > 0.0) {
      final nextG = highestLostSub.getPredictedGradeLetter(gradeScheme);
      insights.add('🔍 Impact Alert: `${highestLostSub.name}` has the highest lost marks (${highestLostSub.marksPermanentlyLost.toStringAsFixed(1)} pts). Your current predicted grade in this subject is `$nextG`.');
    }

    for (final sub in subjects) {
      final double maxPossible = sub.maxPossibleScore;
      final double current = sub.currentScore;
      final double pred = sub.predictedScore;
      
      final currentGp = sub.getPredictedGradePoints(gradeScheme);
      
      final sortedBoundaries = List<GradeBoundary>.from(gradeScheme.boundaries)
        ..sort((a, b) => a.minMarks.compareTo(b.minMarks));
      
      GradeBoundary? nextBoundary;
      for (final b in sortedBoundaries) {
        if (b.gradePoints > currentGp) {
          nextBoundary = b;
          break;
        }
      }

      if (nextBoundary != null && maxPossible >= nextBoundary.minMarks) {
        final double marksNeeded = nextBoundary.minMarks - current;
        final double remaining = sub.remainingAchievableMarks;
        if (marksNeeded <= remaining && marksNeeded > 0) {
          final double percentageNeeded = (marksNeeded / remaining) * 100;
          if (percentageNeeded <= 90) {
            insights.add('🎯 Boundary Push: You need ${marksNeeded.toStringAsFixed(1)} more marks in `${sub.name}` (${percentageNeeded.toStringAsFixed(0)}% of remaining assessments) to secure a grade `${nextBoundary.gradeLetter}`.');
          }
        }
      }
    }

    // Lab / Practical baseline reminder for BMSCE Sem 4 (if loaded)
    final madSubList = subjects.where((s) => s.code == 'MAD');
    if (madSubList.isNotEmpty) {
      final madSub = madSubList.first;
      final internalCompList = madSub.components.where((c) => c.id == 'internal');
      if (internalCompList.isNotEmpty && !internalCompList.first.isCompleted) {
        insights.add('📱 MAD Practical: Ensure your project demo baseline is finalized. Practical internals weigh 50% of the entire course.');
      }
    }

    if (insights.length < 2) {
      insights.add('💡 Tip: Try adjusting the predictions slider on individual subjects to run "What-If" simulations on your SGPA.');
    }

    return insights;
  }
}
