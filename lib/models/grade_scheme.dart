import 'dart:convert';

class GradeBoundary {
  final double minMarks;
  final double maxMarks;
  final String gradeLetter;
  final int gradePoints;

  const GradeBoundary({
    required this.minMarks,
    required this.maxMarks,
    required this.gradeLetter,
    required this.gradePoints,
  });

  Map<String, dynamic> toMap() {
    return {
      'minMarks': minMarks,
      'maxMarks': maxMarks,
      'gradeLetter': gradeLetter,
      'gradePoints': gradePoints,
    };
  }

  factory GradeBoundary.fromMap(Map<String, dynamic> map) {
    return GradeBoundary(
      minMarks: map['minMarks']?.toDouble() ?? 0.0,
      maxMarks: map['maxMarks']?.toDouble() ?? 0.0,
      gradeLetter: map['gradeLetter'] ?? '',
      gradePoints: map['gradePoints']?.toInt() ?? 0,
    );
  }
}

class GradeScheme {
  final List<GradeBoundary> boundaries;

  const GradeScheme({required this.boundaries});

  // Default BMSCE Grading Scheme
  static const GradeScheme defaultBMSCE = GradeScheme(
    boundaries: [
      GradeBoundary(minMarks: 90.0, maxMarks: 100.0, gradeLetter: 'S', gradePoints: 10),
      GradeBoundary(minMarks: 80.0, maxMarks: 89.99, gradeLetter: 'A', gradePoints: 9),
      GradeBoundary(minMarks: 70.0, maxMarks: 79.99, gradeLetter: 'B', gradePoints: 8),
      GradeBoundary(minMarks: 60.0, maxMarks: 69.99, gradeLetter: 'C', gradePoints: 7),
      GradeBoundary(minMarks: 50.0, maxMarks: 59.99, gradeLetter: 'D', gradePoints: 6),
      GradeBoundary(minMarks: 40.0, maxMarks: 49.99, gradeLetter: 'E', gradePoints: 4),
      GradeBoundary(minMarks: 0.0, maxMarks: 39.99, gradeLetter: 'F', gradePoints: 0),
    ],
  );

  GradeBoundary getBoundary(double marks) {
    // Sort boundaries in descending order of minMarks to ensure correct matching
    final sorted = List<GradeBoundary>.from(boundaries)
      ..sort((a, b) => b.minMarks.compareTo(a.minMarks));
    
    for (final boundary in sorted) {
      if (marks >= boundary.minMarks) {
        return boundary;
      }
    }
    return sorted.last; // Fallback to 'F'
  }

  Map<String, dynamic> toMap() {
    return {
      'boundaries': boundaries.map((x) => x.toMap()).toList(),
    };
  }

  factory GradeScheme.fromMap(Map<String, dynamic> map) {
    return GradeScheme(
      boundaries: List<GradeBoundary>.from(
        map['boundaries']?.map((x) => GradeBoundary.fromMap(x)) ?? const [],
      ),
    );
  }

  String toJson() => json.encode(toMap());

  factory GradeScheme.fromJson(String source) => GradeScheme.fromMap(json.decode(source));
}
