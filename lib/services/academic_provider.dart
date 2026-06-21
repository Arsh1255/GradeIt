import 'package:flutter/foundation.dart';
import '../models/subject.dart';
import '../models/subject_type.dart';
import '../models/assessment_component.dart';
import '../models/user_profile.dart';
import '../models/grade_scheme.dart';
import '../core/grading_calculator.dart';
import 'storage_service.dart';

class AcademicProvider with ChangeNotifier {
  final StorageService _storageService = StorageService();
  
  List<Subject> _subjects = [];
  UserProfile _userProfile = UserProfile();
  List<String> _activities = [];
  bool _isLoading = true;
  bool _isDarkMode = false;
  GradeScheme _gradeScheme = GradeScheme.defaultBMSCE;

  List<Subject> get subjects => _subjects;
  UserProfile get userProfile => _userProfile;
  List<String> get activities => _activities;
  bool get isLoading => _isLoading;
  bool get isDarkMode => _isDarkMode;
  GradeScheme get gradeScheme => _gradeScheme;

  void updateGradeScheme(GradeScheme scheme) {
    _gradeScheme = scheme;
    _logActivity('Grading boundaries scheme updated.');
    notifyListeners();
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

    _userProfile = await _storageService.loadUserProfile();
    _subjects = await _storageService.loadSubjects();
    _isDarkMode = await _storageService.loadDarkMode();
    _activities = [
      'Welcome to GradeIt! Semester 4 monitoring initialized.',
      'Active subjects: ADA, OS, SE, LAO, CRP, TFC, MAD, NPTEL.',
    ];
    
    _isLoading = false;
    notifyListeners();
  }

  // --- MUTATORS ---

  Future<void> updateUserProfile(UserProfile profile) async {
    _userProfile = profile;
    await _storageService.saveUserProfile(profile);
    _logActivity('Academic history updated (SGPAs: Sem 1: ${profile.sem1Sgpa}, Sem 2: ${profile.sem2Sgpa}, Sem 3: ${profile.sem3Sgpa})');
    notifyListeners();
  }

  Future<void> updateAssessment({
    required String subjectCode,
    required String assessmentId,
    double? scoredMarks,
    required double predictedMarks,
    required bool isCompleted,
    bool saveToDisk = true,
  }) async {
    final subIndex = _subjects.indexWhere((s) => s.code == subjectCode);
    if (subIndex == -1) return;

    final subject = _subjects[subIndex];
    final compIndex = subject.assessments.indexWhere((a) => a.id == assessmentId);
    if (compIndex == -1) return;

    final oldComponent = subject.assessments[compIndex];
    
    // Determine what changed for the activity log
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

    final updatedComponent = oldComponent.copyWith(
      scoredMarks: scoredMarks,
      predictedMarks: predictedMarks,
      isCompleted: isCompleted,
      clearScoredMarks: !isCompleted,
    );

    final updatedAssessments = List<AssessmentComponent>.from(subject.assessments);
    updatedAssessments[compIndex] = updatedComponent;

    _subjects[subIndex] = subject.copyWith(assessments: updatedAssessments);
    
    if (saveToDisk) {
      await _storageService.saveSubjects(_subjects);
      if (logMsg.isNotEmpty) {
        _logActivity(logMsg);
      }
    }
    notifyListeners();
  }

  Future<void> resetAll() async {
    await _storageService.clearAll();
    await _init();
    _logActivity('System reset. All academic metrics cleared to defaults.');
  }

  void _logActivity(String activity) {
    _activities.insert(0, '[${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}] $activity');
    if (_activities.length > 30) {
      _activities.removeLast();
    }
  }

  // --- DERIVED METRICS ---

  // Semester 4 Credits
  int get sem4TotalCredits => _subjects.fold(0, (sum, s) => sum + s.credits);

  // SGPAs
  double get currentSgpa => GradingCalculator.calculateSgpa(_subjects, gradeScheme: _gradeScheme, usePredictions: false);
  double get predictedSgpa => GradingCalculator.calculateSgpa(_subjects, gradeScheme: _gradeScheme, usePredictions: true);
  double get maxSgpa => GradingCalculator.calculateSgpa(_subjects, gradeScheme: _gradeScheme, useMaxPending: true);
  double get minSgpa => GradingCalculator.calculateSgpa(_subjects, gradeScheme: _gradeScheme, useMinPending: true);

  // CGPAs
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

  // Marks completed, lost, remaining
  double get totalScoredMarks => _subjects.fold(0.0, (sum, s) => sum + s.currentScore);
  double get totalPredictedMarks => _subjects.fold(0.0, (sum, s) => sum + s.predictedScore);
  double get totalMaxMarksPossible => _subjects.fold(0.0, (sum, s) => sum + s.maxPossibleScore);
  double get totalMarksLost => _subjects.fold(0.0, (sum, s) => sum + s.marksPermanentlyLost);
  double get totalRemainingAchievable => _subjects.fold(0.0, (sum, s) => sum + s.remainingAchievableMarks);

  // Semester Completion Percentage
  double get semesterCompletionPercentage {
    if (_subjects.isEmpty) return 0.0;
    int completedComponents = 0;
    int totalComponents = 0;
    
    for (final s in _subjects) {
      for (final a in s.assessments) {
        totalComponents++;
        if (a.isCompleted) completedComponents++;
      }
    }
    return (completedComponents / totalComponents) * 100;
  }

  // --- RULE-BASED DYNAMIC INSIGHT ENGINE ---
  
  List<String> get academicInsights {
    final List<String> insights = [];

    if (_subjects.isEmpty) return ['Loading academic analytics...'];

    // 1. General Standing Insight
    final double predSgpa = predictedSgpa;
    if (predSgpa >= 9.5) {
      insights.add('🏆 Exceptional Performance! Your predicted SGPA of ${predSgpa.toStringAsFixed(2)} places you in the top tier. Keep executing at this level.');
    } else if (predSgpa >= 8.5) {
      insights.add('🌟 Strong Standing. Your predicted SGPA is ${predSgpa.toStringAsFixed(2)}. A slight push in your upcoming final exams could elevate you above 9.0.');
    } else if (predSgpa >= 7.0) {
      insights.add('📈 Solid progress. You are on track for a ${predSgpa.toStringAsFixed(2)} SGPA. Identify subjects with lost marks to prioritize your study hours.');
    } else {
      insights.add('⚠️ Attention Required. Predicted SGPA is ${predSgpa.toStringAsFixed(2)}. Focus on securing full internal marks (AATs/Labs) to establish a safe baseline before SEE.');
    }

    // 2. Risk / Lost Marks Analysis
    final sortedByLost = List<Subject>.from(_subjects)
      ..sort((a, b) => b.marksPermanentlyLost.compareTo(a.marksPermanentlyLost));
    final highestLostSub = sortedByLost.first;

    if (highestLostSub.marksPermanentlyLost > 0.0) {
      insights.add('🔍 Impact Alert: `${highestLostSub.name}` has the highest lost marks (${highestLostSub.marksPermanentlyLost.toStringAsFixed(1)} pts). Your maximum possible grade in this subject is now `${highestLostSub.maxPossibleScore >= 90 ? 'S' : highestLostSub.maxPossibleScore >= 80 ? 'A' : 'B'}`.');
    }

    // 3. Subject-specific predictions / critical paths
    for (final sub in _subjects) {
      final double maxPossible = sub.maxPossibleScore;
      final double current = sub.currentScore;
      final double pred = sub.predictedScore;
      
      // If close to next grade boundary
      final currentGradePoints = Subject.getGradePoints(pred);
      double nextBoundary = 0.0;
      String nextGrade = '';
      if (pred < 40) { nextBoundary = 40; nextGrade = 'E'; }
      else if (pred < 50) { nextBoundary = 50; nextGrade = 'D'; }
      else if (pred < 60) { nextBoundary = 60; nextGrade = 'C'; }
      else if (pred < 70) { nextBoundary = 70; nextGrade = 'B'; }
      else if (pred < 80) { nextBoundary = 80; nextGrade = 'A'; }
      else if (pred < 90) { nextBoundary = 90; nextGrade = 'S'; }

      if (nextBoundary > 0.0 && maxPossible >= nextBoundary) {
        final double marksNeeded = nextBoundary - current;
        final double remaining = sub.remainingAchievableMarks;
        if (marksNeeded <= remaining && marksNeeded > 0) {
          final double percentageNeeded = (marksNeeded / remaining) * 100;
          if (percentageNeeded <= 90) {
            insights.add('🎯 Boundary Push: You need ${marksNeeded.toStringAsFixed(1)} more marks in `${sub.name}` (${percentageNeeded.toStringAsFixed(0)}% of remaining assessments) to secure a grade `$nextGrade`.');
          }
        }
      }
    }

    // 4. Lab / Practical baseline reminder
    final madSub = _subjects.firstWhere((s) => s.type == SubjectType.practical, orElse: () => _subjects.first);
    final madInternal = madSub.assessments.firstWhere((a) => a.id == 'internal', orElse: () => madSub.assessments.first);
    if (!madInternal.isCompleted) {
      insights.add('📱 MAD Practical: Ensure your project demo baseline is finalized. Practical internals weigh 50% of the entire course.');
    }

    // Fallback if list is short
    if (insights.length < 2) {
      insights.add('💡 Tip: Try adjusting the predictions slider on individual subjects to run "What-If" simulations on your SGPA.');
    }

    return insights;
  }
}
