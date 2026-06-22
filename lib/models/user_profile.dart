import 'dart:convert';

class PriorSemester {
  final double sgpa;
  final int credits;

  PriorSemester({required this.sgpa, required this.credits});

  Map<String, dynamic> toMap() {
    return {
      'sgpa': sgpa,
      'credits': credits,
    };
  }

  factory PriorSemester.fromMap(Map<String, dynamic> map) {
    return PriorSemester(
      sgpa: (map['sgpa'] as num?)?.toDouble() ?? 10.0,
      credits: (map['credits'] as num?)?.toInt() ?? 20,
    );
  }
}

class UserProfile {
  final String name;
  final String usn;
  final List<PriorSemester> priorSemesters;

  UserProfile({
    this.name = 'Name...',
    this.usn = '1BMXXCSXXX',
    List<PriorSemester>? priorSemesters,
  }) : this.priorSemesters = priorSemesters ?? [];

  // Calculate prior total grade points earned
  double get priorTotalGradePoints {
    return priorSemesters.fold(0.0, (sum, sem) => sum + (sem.sgpa * sem.credits));
  }

  // Calculate prior total credits
  int get priorTotalCredits {
    return priorSemesters.fold(0, (sum, sem) => sum + sem.credits);
  }

  // Calculate prior CGPA
  double get priorCgpa {
    final credits = priorTotalCredits;
    if (credits == 0) return 0.0;
    return priorTotalGradePoints / credits;
  }

  UserProfile copyWith({
    String? name,
    String? usn,
    List<PriorSemester>? priorSemesters,
  }) {
    return UserProfile(
      name: name ?? this.name,
      usn: usn ?? this.usn,
      priorSemesters: priorSemesters ?? this.priorSemesters,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'usn': usn,
      'priorSemesters': priorSemesters.map((x) => x.toMap()).toList(),
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    List<PriorSemester> priorSems;
    if (map['priorSemesters'] != null) {
      priorSems = List<PriorSemester>.from(
        (map['priorSemesters'] as List).map((x) => PriorSemester.fromMap(x))
      );
    } else {
      // Migrate legacy fields:
      priorSems = [];
      if (map.containsKey('sem1Sgpa') || map.containsKey('sem1Credits')) {
        priorSems.add(PriorSemester(
          sgpa: (map['sem1Sgpa'] as num?)?.toDouble() ?? 10.0,
          credits: (map['sem1Credits'] as num?)?.toInt() ?? 20,
        ));
      }
      if (map.containsKey('sem2Sgpa') || map.containsKey('sem2Credits')) {
        priorSems.add(PriorSemester(
          sgpa: (map['sem2Sgpa'] as num?)?.toDouble() ?? 10.0,
          credits: (map['sem2Credits'] as num?)?.toInt() ?? 20,
        ));
      }
      if (map.containsKey('sem3Sgpa') || map.containsKey('sem3Credits')) {
        priorSems.add(PriorSemester(
          sgpa: (map['sem3Sgpa'] as num?)?.toDouble() ?? 10.0,
          credits: (map['sem3Credits'] as num?)?.toInt() ?? 22,
        ));
      }
      if (priorSems.isEmpty) {
        priorSems = [
          PriorSemester(sgpa: 10.0, credits: 20),
          PriorSemester(sgpa: 10.0, credits: 20),
          PriorSemester(sgpa: 10.0, credits: 22),
        ];
      }
    }

    return UserProfile(
      name: map['name'] ?? 'Name...',
      usn: map['usn'] ?? '1BMXXCSXXX',
      priorSemesters: priorSems,
    );
  }

  String toJson() => json.encode(toMap());

  factory UserProfile.fromJson(String source) => UserProfile.fromMap(json.decode(source));
}
