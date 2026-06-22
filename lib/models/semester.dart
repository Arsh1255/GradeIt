import 'dart:convert';
import 'subject.dart';
import 'generic_component.dart';
import 'grade_scheme.dart';

class Semester {
  final String name;
  final String collegeName;
  final String branchName;
  final int totalCredits;
  final List<Subject> subjects;
  final GradeScheme gradeScheme;

  Semester({
    required this.name,
    this.collegeName = '',
    this.branchName = '',
    required this.totalCredits,
    required this.subjects,
    this.gradeScheme = GradeScheme.defaultBMSCE,
  });

  // Calculate overall SGPA from subjects
  double calculateSgpa({bool usePredictions = false, bool useMaxPending = false, bool useMinPending = false}) {
    if (subjects.isEmpty) return 0.0;
    
    double totalPoints = 0.0;
    int totalSubjectCredits = 0;

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

      final gp = gradeScheme.getBoundary(score).gradePoints;
      totalPoints += gp * subject.credits;
      totalSubjectCredits += subject.credits;
    }

    if (totalSubjectCredits == 0) return 0.0;
    return totalPoints / totalSubjectCredits;
  }

  Semester copyWith({
    String? name,
    String? collegeName,
    String? branchName,
    int? totalCredits,
    List<Subject>? subjects,
    GradeScheme? gradeScheme,
  }) {
    return Semester(
      name: name ?? this.name,
      collegeName: collegeName ?? this.collegeName,
      branchName: branchName ?? this.branchName,
      totalCredits: totalCredits ?? this.totalCredits,
      subjects: subjects ?? this.subjects,
      gradeScheme: gradeScheme ?? this.gradeScheme,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'collegeName': collegeName,
      'branchName': branchName,
      'totalCredits': totalCredits,
      'subjects': subjects.map((x) => x.toMap()).toList(),
      'gradeScheme': gradeScheme.toMap(),
    };
  }

  factory Semester.fromMap(Map<String, dynamic> map) {
    return Semester(
      name: map['name'] ?? '',
      collegeName: map['collegeName'] ?? '',
      branchName: map['branchName'] ?? '',
      totalCredits: map['totalCredits']?.toInt() ?? 0,
      subjects: List<Subject>.from(map['subjects']?.map((x) => Subject.fromMap(x)) ?? const []),
      gradeScheme: map['gradeScheme'] != null ? GradeScheme.fromMap(map['gradeScheme']) : GradeScheme.defaultBMSCE,
    );
  }

  String toJson() => json.encode(toMap());

  factory Semester.fromJson(String source) => Semester.fromMap(json.decode(source));

  // --- DEFAULT TEMPLATE FACTORY ---
  
  static Semester defaultBMSCESem4() {
    // 1. Integrated Components (ADA, OS)
    List<GenericComponent> createIntegratedComponents() => [
      GenericComponent(
        id: 'cie_group',
        name: 'CIE',
        type: 'grouped',
        weight: 20, // best_2 of 3×10 = 20
        selectionRule: 'best_2',
        children: [
          GenericComponent(id: 'cie1', name: 'CIE 1', type: 'standalone', maxMarks: 10, weight: 10),
          GenericComponent(id: 'cie2', name: 'CIE 2', type: 'standalone', maxMarks: 10, weight: 10),
          GenericComponent(id: 'cie3', name: 'CIE 3', type: 'standalone', maxMarks: 10, weight: 10),
        ],
      ),
      GenericComponent(id: 'aat', name: 'AAT', type: 'standalone', maxMarks: 5, weight: 5),
      GenericComponent(id: 'lab', name: 'Lab Internal', type: 'standalone', maxMarks: 25, weight: 25),
      GenericComponent(id: 'see', name: 'Semester End Exam', type: 'standalone', maxMarks: 100, weight: 50),
    ];

    // 2. Theory A Components (SE, LAO)
    List<GenericComponent> createTheoryAComponents() => [
      GenericComponent(
        id: 'cie_group',
        name: 'CIE',
        type: 'grouped',
        weight: 40, // best_2 of 3×20 = 40
        selectionRule: 'best_2',
        children: [
          GenericComponent(id: 'cie1', name: 'CIE 1', type: 'standalone', maxMarks: 20, weight: 20),
          GenericComponent(id: 'cie2', name: 'CIE 2', type: 'standalone', maxMarks: 20, weight: 20),
          GenericComponent(id: 'cie3', name: 'CIE 3', type: 'standalone', maxMarks: 20, weight: 20),
        ],
      ),
      GenericComponent(id: 'aat', name: 'AAT', type: 'standalone', maxMarks: 5, weight: 5),
      GenericComponent(id: 'quiz', name: 'Quiz', type: 'standalone', maxMarks: 5, weight: 5),
      GenericComponent(id: 'see', name: 'Semester End Exam', type: 'standalone', maxMarks: 100, weight: 50),
    ];

    // 3. Theory B Components (CRP, TFC)
    List<GenericComponent> createTheoryBComponents() => [
      GenericComponent(
        id: 'cie_group',
        name: 'CIE',
        type: 'grouped',
        weight: 40, // best_2 of 3×20 = 40
        selectionRule: 'best_2',
        children: [
          GenericComponent(id: 'cie1', name: 'CIE 1', type: 'standalone', maxMarks: 20, weight: 20),
          GenericComponent(id: 'cie2', name: 'CIE 2', type: 'standalone', maxMarks: 20, weight: 20),
          GenericComponent(id: 'cie3', name: 'CIE 3', type: 'standalone', maxMarks: 20, weight: 20),
        ],
      ),
      GenericComponent(id: 'aat', name: 'AAT', type: 'standalone', maxMarks: 10, weight: 10),
      GenericComponent(id: 'see', name: 'Semester End Exam', type: 'standalone', maxMarks: 100, weight: 50),
    ];

    // 4. Practical Components (MAD)
    List<GenericComponent> createPracticalComponents() => [
      GenericComponent(id: 'internal', name: 'Practical Internal', type: 'standalone', maxMarks: 50, weight: 50),
      GenericComponent(id: 'see', name: 'Semester End Exam', type: 'standalone', maxMarks: 50, weight: 50),
    ];

    // 5. External Components (NPTEL)
    List<GenericComponent> createExternalComponents() => [
      GenericComponent(id: 'assignments', name: 'Assignments', type: 'standalone', maxMarks: 25, weight: 25),
      GenericComponent(id: 'see', name: 'Final Exam', type: 'standalone', maxMarks: 75, weight: 75),
    ];

    final subjectsList = [
      Subject(code: 'ADA', name: 'Analysis and Design of Algorithms', credits: 4, components: createIntegratedComponents()),
      Subject(code: 'OS', name: 'Operating Systems', credits: 4, components: createIntegratedComponents()),
      Subject(code: 'SE', name: 'Software Engineering', credits: 3, components: createTheoryAComponents()),
      Subject(code: 'LAO', name: 'Linear Algebra and Optimization', credits: 3, components: createTheoryAComponents()),
      Subject(code: 'CRP', name: 'Cryptography', credits: 3, components: createTheoryBComponents()),
      Subject(code: 'TFC', name: 'Theoretical Foundations of Computation', credits: 3, components: createTheoryBComponents()),
      Subject(code: 'MAD', name: 'Mobile Application Development', credits: 1, components: createPracticalComponents()),
      Subject(code: 'NPTEL', name: 'NPTEL Course', credits: 1, components: createExternalComponents()),
    ];

    return Semester(
      name: 'BMSCE CSE Semester 4',
      collegeName: 'BMS College of Engineering',
      branchName: 'Computer Science and Engineering',
      totalCredits: 22,
      subjects: subjectsList,
      gradeScheme: GradeScheme.defaultBMSCE,
    );
  }
}
