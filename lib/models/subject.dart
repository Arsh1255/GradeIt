import 'dart:convert';
import 'assessment_component.dart';
import 'subject_type.dart';
import 'grade_scheme.dart';

class Subject {
  final String code;
  final String name;
  final int credits;
  final SubjectType type;
  final List<AssessmentComponent> assessments;

  Subject({
    required this.code,
    required this.name,
    required this.credits,
    required this.type,
    required this.assessments,
  });

  // Factory to create a default subject configuration based on its type
  factory Subject.createDefault({
    required String name,
    required String code,
    required int credits,
    required SubjectType type,
  }) {
    List<AssessmentComponent> defaultAssessments = [];

    switch (type) {
      case SubjectType.integrated:
        // Integrated Course (ADA, OS): 20 (CIE best 2 of 3) + 5 (AAT) + 25 (Lab) + 50 (SEE)
        defaultAssessments = [
          AssessmentComponent(id: 'cie1', name: 'CIE 1', maxMarks: 10, weight: 10),
          AssessmentComponent(id: 'cie2', name: 'CIE 2', maxMarks: 10, weight: 10),
          AssessmentComponent(id: 'cie3', name: 'CIE 3', maxMarks: 10, weight: 10),
          AssessmentComponent(id: 'aat', name: 'AAT', maxMarks: 5, weight: 5),
          AssessmentComponent(id: 'lab', name: 'Lab Internal', maxMarks: 25, weight: 25),
          AssessmentComponent(id: 'see', name: 'Semester End Exam', maxMarks: 100, weight: 50),
        ];
        break;

      case SubjectType.theoryA:
        // Theory Course Type A (SE, LAO): 40 (CIE best 2 of 3) + 5 (AAT) + 5 (Quiz) + 50 (SEE)
        defaultAssessments = [
          AssessmentComponent(id: 'cie1', name: 'CIE 1', maxMarks: 20, weight: 20),
          AssessmentComponent(id: 'cie2', name: 'CIE 2', maxMarks: 20, weight: 20),
          AssessmentComponent(id: 'cie3', name: 'CIE 3', maxMarks: 20, weight: 20),
          AssessmentComponent(id: 'aat', name: 'AAT', maxMarks: 5, weight: 5),
          AssessmentComponent(id: 'quiz', name: 'Quiz', maxMarks: 5, weight: 5),
          AssessmentComponent(id: 'see', name: 'Semester End Exam', maxMarks: 100, weight: 50),
        ];
        break;

      case SubjectType.theoryB:
        // Theory Course Type B (CRP, TFC): 40 (CIE best 2 of 3) + 10 (AAT) + 50 (SEE)
        defaultAssessments = [
          AssessmentComponent(id: 'cie1', name: 'CIE 1', maxMarks: 20, weight: 20),
          AssessmentComponent(id: 'cie2', name: 'CIE 2', maxMarks: 20, weight: 20),
          AssessmentComponent(id: 'cie3', name: 'CIE 3', maxMarks: 20, weight: 20),
          AssessmentComponent(id: 'aat', name: 'AAT', maxMarks: 10, weight: 10),
          AssessmentComponent(id: 'see', name: 'Semester End Exam', maxMarks: 100, weight: 50),
        ];
        break;

      case SubjectType.practical:
        // Practical Course (MAD): 50 (Internal) + 50 (SEE)
        defaultAssessments = [
          AssessmentComponent(id: 'internal', name: 'Practical Internal', maxMarks: 50, weight: 50),
          AssessmentComponent(id: 'see', name: 'Semester End Exam', maxMarks: 50, weight: 50),
        ];
        break;

      case SubjectType.external:
        // External Course (NPTEL): 25 (Assignments) + 75 (Final Exam)
        defaultAssessments = [
          AssessmentComponent(id: 'assignments', name: 'Assignments', maxMarks: 25, weight: 25),
          AssessmentComponent(id: 'see', name: 'Final Exam', maxMarks: 75, weight: 75),
        ];
        break;
    }

    return Subject(
      code: code,
      name: name,
      credits: credits,
      type: type,
      assessments: defaultAssessments,
    );
  }

  // --- GRAD CALCULATIONS ---

  // CIE Best 2 of 3 calculations helper
  List<double> _getCieScaledScores(bool usePredictions, bool useMaxPending) {
    final cieList = assessments.where((a) => a.id.startsWith('cie')).toList();
    if (cieList.isEmpty) return [];

    return cieList.map((a) {
      if (a.isCompleted && a.scoredMarks != null) {
        return a.currentScaledScore;
      }
      if (useMaxPending) {
        return a.maxPossibleScaledScore;
      }
      if (usePredictions) {
        return a.predictedScaledScore;
      }
      return a.minPossibleScaledScore; // 0.0
    }).toList();
  }

  double _calculateCieTotal(List<double> scores) {
    if (scores.isEmpty) return 0.0;
    if (scores.length <= 2) {
      return scores.reduce((a, b) => a + b);
    }
    // Best 2 of 3
    final sorted = List<double>.from(scores)..sort();
    return sorted[sorted.length - 1] + sorted[sorted.length - 2];
  }

  // Calculate generic non-CIE components
  double _calculateNonCieTotal(bool usePredictions, bool useMaxPending) {
    final nonCieList = assessments.where((a) => !a.id.startsWith('cie')).toList();
    if (nonCieList.isEmpty) return 0.0;

    return nonCieList.map((a) {
      if (a.isCompleted && a.scoredMarks != null) {
        return a.currentScaledScore;
      }
      if (useMaxPending) {
        return a.maxPossibleScaledScore;
      }
      if (usePredictions) {
        return a.predictedScaledScore;
      }
      return a.minPossibleScaledScore;
    }).fold(0.0, (sum, score) => sum + score);
  }

  // 1. Current Score (completed assessments only)
  double get currentScore {
    // For CIE: calculate best completed CIE scores
    final cieScores = assessments
        .where((a) => a.id.startsWith('cie') && a.isCompleted && a.scoredMarks != null)
        .map((a) => a.currentScaledScore)
        .toList();
    
    // We sum whatever completed CIE scores we have (up to 2, or best 2 if 3 completed)
    double cieTotal = 0.0;
    if (cieScores.isNotEmpty) {
      if (cieScores.length <= 2) {
        cieTotal = cieScores.fold(0.0, (a, b) => a + b);
      } else {
        final sorted = List<double>.from(cieScores)..sort();
        cieTotal = sorted[sorted.length - 1] + sorted[sorted.length - 2];
      }
    }

    final nonCieTotal = assessments
        .where((a) => !a.id.startsWith('cie') && a.isCompleted && a.scoredMarks != null)
        .map((a) => a.currentScaledScore)
        .fold(0.0, (sum, score) => sum + score);

    return cieTotal + nonCieTotal;
  }

  // 2. Predicted Score (mix of actual completed + predictions for pending)
  double get predictedScore {
    final cieScores = _getCieScaledScores(true, false);
    final cieTotal = _calculateCieTotal(cieScores);
    final nonCieTotal = _calculateNonCieTotal(true, false);
    return cieTotal + nonCieTotal;
  }

  // 3. Maximum Possible Score (actual completed + 100% on pending)
  double get maxPossibleScore {
    final cieScores = _getCieScaledScores(false, true);
    final cieTotal = _calculateCieTotal(cieScores);
    final nonCieTotal = _calculateNonCieTotal(false, true);
    return cieTotal + nonCieTotal;
  }

  // 4. Minimum Possible Score (actual completed + 0% on pending)
  double get minPossibleScore {
    final cieScores = _getCieScaledScores(false, false);
    final cieTotal = _calculateCieTotal(cieScores);
    final nonCieTotal = _calculateNonCieTotal(false, false);
    return cieTotal + nonCieTotal;
  }

  // 5. Marks Permanently Lost
  double get marksPermanentlyLost {
    final lost = 100.0 - maxPossibleScore;
    return lost < 0 ? 0.0 : lost;
  }

  // 6. Remaining Achievable Marks (maximum marks of all pending components)
  double get remainingAchievableMarks {
    final pendingAssessments = assessments.where((a) => !a.isCompleted).toList();
    if (pendingAssessments.isEmpty) return 0.0;
    
    // For CIE, we calculate how much the CIE total can increase
    final currentCieScores = _getCieScaledScores(false, false);
    final currentCieTotal = _calculateCieTotal(currentCieScores);
    
    final maxCieScores = _getCieScaledScores(false, true);
    final maxCieTotal = _calculateCieTotal(maxCieScores);
    
    final cieIncrease = maxCieTotal - currentCieTotal;
    
    // For other assessments, we sum their weights
    final nonCieWeight = pendingAssessments
        .where((a) => !a.id.startsWith('cie'))
        .map((a) => a.weight)
        .fold(0.0, (sum, w) => sum + w);
        
    return cieIncrease + nonCieWeight;
  }

  // Subject Grade Letter and Grade Points based on Predicted Score
  String getPredictedGradeLetter([GradeScheme scheme = GradeScheme.defaultBMSCE]) {
    return scheme.getBoundary(predictedScore).gradeLetter;
  }

  int getPredictedGradePoints([GradeScheme scheme = GradeScheme.defaultBMSCE]) {
    return scheme.getBoundary(predictedScore).gradePoints;
  }

  String get predictedGradeLetter => getPredictedGradeLetter();
  int get predictedGradePoints => getPredictedGradePoints();

  // Helper static methods to calculate grade points from total marks
  static String getGradeLetter(double marks, [GradeScheme scheme = GradeScheme.defaultBMSCE]) {
    return scheme.getBoundary(marks).gradeLetter;
  }

  static int getGradePoints(double marks, [GradeScheme scheme = GradeScheme.defaultBMSCE]) {
    return scheme.getBoundary(marks).gradePoints;
  }

  Subject copyWith({
    String? code,
    String? name,
    int? credits,
    SubjectType? type,
    List<AssessmentComponent>? assessments,
  }) {
    return Subject(
      code: code ?? this.code,
      name: name ?? this.name,
      credits: credits ?? this.credits,
      type: type ?? this.type,
      assessments: assessments ?? this.assessments,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'name': name,
      'credits': credits,
      'type': type.index,
      'assessments': assessments.map((x) => x.toMap()).toList(),
    };
  }

  factory Subject.fromMap(Map<String, dynamic> map) {
    return Subject(
      code: map['code'] ?? '',
      name: map['name'] ?? '',
      credits: map['credits']?.toInt() ?? 0,
      type: SubjectType.values[map['type']],
      assessments: List<AssessmentComponent>.from(
        map['assessments']?.map((x) => AssessmentComponent.fromMap(x)) ?? const [],
      ),
    );
  }

  String toJson() => json.encode(toMap());

  factory Subject.fromJson(String source) => Subject.fromMap(json.decode(source));
}
