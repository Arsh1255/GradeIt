import 'dart:convert';

class UserProfile {
  final String name;
  final String usn;
  final double sem1Sgpa;
  final int sem1Credits;
  final double sem2Sgpa;
  final int sem2Credits;
  final double sem3Sgpa;
  final int sem3Credits;

  UserProfile({
    this.name = 'Name...',
    this.usn = '1BMXXCSXXX',
    this.sem1Sgpa = 10.0,
    this.sem1Credits = 20,
    this.sem2Sgpa = 10.0,
    this.sem2Credits = 20,
    this.sem3Sgpa = 10.0,
    this.sem3Credits = 22,
  });

  // Calculate prior total grade points earned (Sem 1 + Sem 2 + Sem 3)
  double get priorTotalGradePoints {
    return (sem1Sgpa * sem1Credits) + (sem2Sgpa * sem2Credits) + (sem3Sgpa * sem3Credits);
  }

  // Calculate prior total credits (Sem 1 + Sem 2 + Sem 3)
  int get priorTotalCredits {
    return sem1Credits + sem2Credits + sem3Credits;
  }

  // Calculate prior CGPA (Sem 1-3)
  double get priorCgpa {
    final credits = priorTotalCredits;
    if (credits == 0) return 0.0;
    return priorTotalGradePoints / credits;
  }

  UserProfile copyWith({
    String? name,
    String? usn,
    double? sem1Sgpa,
    int? sem1Credits,
    double? sem2Sgpa,
    int? sem2Credits,
    double? sem3Sgpa,
    int? sem3Credits,
  }) {
    return UserProfile(
      name: name ?? this.name,
      usn: usn ?? this.usn,
      sem1Sgpa: sem1Sgpa ?? this.sem1Sgpa,
      sem1Credits: sem1Credits ?? this.sem1Credits,
      sem2Sgpa: sem2Sgpa ?? this.sem2Sgpa,
      sem2Credits: sem2Credits ?? this.sem2Credits,
      sem3Sgpa: sem3Sgpa ?? this.sem3Sgpa,
      sem3Credits: sem3Credits ?? this.sem3Credits,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'usn': usn,
      'sem1Sgpa': sem1Sgpa,
      'sem1Credits': sem1Credits,
      'sem2Sgpa': sem2Sgpa,
      'sem2Credits': sem2Credits,
      'sem3Sgpa': sem3Sgpa,
      'sem3Credits': sem3Credits,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      name: map['name'] ?? 'Name...',
      usn: map['usn'] ?? '1BMXXCSXXX',
      sem1Sgpa: (map['sem1Sgpa'] as num?)?.toDouble() ?? 10.0,
      sem1Credits: (map['sem1Credits'] as num?)?.toInt() ?? 20,
      sem2Sgpa: (map['sem2Sgpa'] as num?)?.toDouble() ?? 10.0,
      sem2Credits: (map['sem2Credits'] as num?)?.toInt() ?? 20,
      sem3Sgpa: (map['sem3Sgpa'] as num?)?.toDouble() ?? 10.0,
      sem3Credits: (map['sem3Credits'] as num?)?.toInt() ?? 22,
    );
  }

  String toJson() => json.encode(toMap());

  factory UserProfile.fromJson(String source) => UserProfile.fromMap(json.decode(source));
}
