import 'dart:convert';

class AssessmentComponent {
  final String id;
  final String name;
  final double maxMarks;
  final double weight; // The scaled mark weight (e.g., 10 or 20)
  final double? scoredMarks; // Null if pending
  final double predictedMarks; // Predicted value, defaults to 0
  final bool isCompleted;

  AssessmentComponent({
    required this.id,
    required this.name,
    required this.maxMarks,
    required this.weight,
    this.scoredMarks,
    this.predictedMarks = 0.0,
    this.isCompleted = false,
  });

  // Returns the actual scaled score if completed, otherwise 0.0
  double get currentScaledScore {
    if (!isCompleted || scoredMarks == null) return 0.0;
    return (scoredMarks! / maxMarks) * weight;
  }

  // Returns the predicted scaled score if pending, otherwise the actual scaled score
  double get predictedScaledScore {
    final double marks = isCompleted ? (scoredMarks ?? 0.0) : predictedMarks;
    return (marks / maxMarks) * weight;
  }

  // Returns the maximum possible scaled marks from this component
  double get maxPossibleScaledScore {
    if (isCompleted && scoredMarks != null) {
      return currentScaledScore;
    }
    return weight;
  }

  // Returns the minimum possible scaled marks from this component
  double get minPossibleScaledScore {
    if (isCompleted && scoredMarks != null) {
      return currentScaledScore;
    }
    return 0.0;
  }

  AssessmentComponent copyWith({
    String? id,
    String? name,
    double? maxMarks,
    double? weight,
    double? scoredMarks,
    double? predictedMarks,
    bool? isCompleted,
    bool clearScoredMarks = false,
  }) {
    return AssessmentComponent(
      id: id ?? this.id,
      name: name ?? this.name,
      maxMarks: maxMarks ?? this.maxMarks,
      weight: weight ?? this.weight,
      scoredMarks: clearScoredMarks ? null : (scoredMarks ?? this.scoredMarks),
      predictedMarks: predictedMarks ?? this.predictedMarks,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'maxMarks': maxMarks,
      'weight': weight,
      'scoredMarks': scoredMarks,
      'predictedMarks': predictedMarks,
      'isCompleted': isCompleted,
    };
  }

  factory AssessmentComponent.fromMap(Map<String, dynamic> map) {
    return AssessmentComponent(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      maxMarks: (map['maxMarks'] as num).toDouble(),
      weight: (map['weight'] as num).toDouble(),
      scoredMarks: map['scoredMarks'] != null ? (map['scoredMarks'] as num).toDouble() : null,
      predictedMarks: (map['predictedMarks'] as num).toDouble(),
      isCompleted: map['isCompleted'] ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory AssessmentComponent.fromJson(String source) => AssessmentComponent.fromMap(json.decode(source));
}
