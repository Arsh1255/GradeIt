import '../models/subject.dart';
import '../models/user_profile.dart';
import '../models/grade_scheme.dart';

class GradingCalculator {
  // Calculate SGPA for a given list of subjects and score strategy
  static double calculateSgpa(
    List<Subject> subjects, {
    GradeScheme gradeScheme = GradeScheme.defaultBMSCE,
    bool usePredictions = false,
    bool useMaxPending = false,
    bool useMinPending = false,
  }) {
    if (subjects.isEmpty) return 0.0;

    int totalCredits = 0;
    double weightedGradePointsSum = 0.0;

    for (final subject in subjects) {
      double score = 0.0;
      if (useMaxPending) {
        score = subject.maxPossibleScore;
      } else if (useMinPending) {
        score = subject.minPossibleScore;
      } else if (usePredictions) {
        score = subject.predictedScore;
      } else {
        score = subject.currentScore;
      }

      final gradePoints = gradeScheme.getBoundary(score).gradePoints;
      weightedGradePointsSum += (gradePoints * subject.credits);
      totalCredits += subject.credits;
    }

    if (totalCredits == 0) return 0.0;
    return weightedGradePointsSum / totalCredits;
  }

  // Calculate CGPA including Semester 4
  static double calculateCgpa({
    required UserProfile profile,
    required double sem4Sgpa,
    required int sem4Credits,
  }) {
    final double priorPoints = profile.priorTotalGradePoints;
    final int priorCredits = profile.priorTotalCredits;

    final double totalPoints = priorPoints + (sem4Sgpa * sem4Credits);
    final int totalCredits = priorCredits + sem4Credits;

    if (totalCredits == 0) return 0.0;
    return totalPoints / totalCredits;
  }
}
