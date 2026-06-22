import 'dart:convert';
import 'generic_component.dart';
import 'grade_scheme.dart';

class Subject {
  final String code;
  final String name;
  final int credits;
  final List<GenericComponent> components;

  Subject({
    required this.code,
    required this.name,
    required this.credits,
    required this.components,
  });

  // --- GRAD CALCULATIONS ---

  // 1. Current Score (completed assessments only)
  double get currentScore {
    if (components.isEmpty) return 0.0;
    return components
        .map((c) => c.currentScaledScore)
        .fold(0.0, (sum, score) => sum + score);
  }

  // 2. Predicted Score (mix of actual completed + predictions for pending)
  double get predictedScore {
    if (components.isEmpty) return 0.0;
    return components
        .map((c) => c.predictedScaledScore)
        .fold(0.0, (sum, score) => sum + score);
  }

  // 3. Maximum Possible Score (actual completed + 100% on pending)
  double get maxPossibleScore {
    if (components.isEmpty) return 0.0;
    return components
        .map((c) => c.maxPossibleScaledScore)
        .fold(0.0, (sum, score) => sum + score);
  }

  // 4. Minimum Possible Score (actual completed + 0% on pending)
  double get minPossibleScore {
    if (components.isEmpty) return 0.0;
    return components
        .map((c) => c.minPossibleScaledScore)
        .fold(0.0, (sum, score) => sum + score);
  }

  // 5. Marks Permanently Lost
  double get marksPermanentlyLost {
    final lost = 100.0 - maxPossibleScore;
    return lost < 0 ? 0.0 : lost;
  }

  // 6. Remaining Achievable Marks (maximum marks of all pending components)
  double get remainingAchievableMarks {
    final remaining = maxPossibleScore - currentScore;
    return remaining < 0.0 ? 0.0 : remaining;
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

  Subject copyWith({
    String? code,
    String? name,
    int? credits,
    List<GenericComponent>? components,
  }) {
    return Subject(
      code: code ?? this.code,
      name: name ?? this.name,
      credits: credits ?? this.credits,
      components: components ?? this.components,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'name': name,
      'credits': credits,
      'components': components.map((x) => x.toMap()).toList(),
    };
  }

  factory Subject.fromMap(Map<String, dynamic> map) {
    return Subject(
      code: map['code'] ?? '',
      name: map['name'] ?? '',
      credits: map['credits']?.toInt() ?? 0,
      components: List<GenericComponent>.from(
        map['components']?.map((x) => GenericComponent.fromMap(x)) ??
        map['assessments']?.map((x) => GenericComponent.fromMap(x)) ?? // Fallback to handle migration
        const [],
      ),
    );
  }

  String toJson() => json.encode(toMap());

  factory Subject.fromJson(String source) => Subject.fromMap(json.decode(source));
}
