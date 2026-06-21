enum SubjectType {
  integrated,
  theoryA,
  theoryB,
  practical,
  external,
}

extension SubjectTypeExtension on SubjectType {
  String get displayName {
    switch (this) {
      case SubjectType.integrated:
        return 'Integrated Course';
      case SubjectType.theoryA:
        return 'Theory Course (Type A)';
      case SubjectType.theoryB:
        return 'Theory Course (Type B)';
      case SubjectType.practical:
        return 'Practical Course';
      case SubjectType.external:
        return 'External Course';
    }
  }
}
