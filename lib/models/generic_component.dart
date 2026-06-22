import 'dart:convert';

class GenericComponent {
  final String id;
  final String name;
  final String type; // "standalone" or "grouped"
  
  // Standalone properties
  final double maxMarks;
  final double _weight;
  final double? scoredMarks;
  final double predictedMarks;
  final bool isCompleted;

  // Grouped properties
  final List<GenericComponent> children;
  final String selectionRule; // "sum_all", "best_1", "best_2", "best_3"

  GenericComponent({
    required this.id,
    required this.name,
    required this.type,
    this.maxMarks = 100.0,
    double weight = 100.0,
    this.scoredMarks,
    this.predictedMarks = 0.0,
    this.isCompleted = false,
    this.children = const [],
    this.selectionRule = 'sum_all',
  }) : _weight = weight;

  double get weight {
    if (type == 'standalone') return _weight;
    if (children.isEmpty) return _weight;
    final childWeights = children.map((c) => c.weight).toList();
    if (selectionRule == 'sum_all') {
      return childWeights.fold(0.0, (s, w) => s + w);
    }
    final k = int.tryParse(selectionRule.split('_').last) ?? 1;
    final sorted = List<double>.from(childWeights)..sort((a, b) => b.compareTo(a));
    return sorted.take(k).fold(0.0, (s, w) => s + w);
  }

  // Calculate standard stand-alone metrics
  double get _rawCurrentScaledScore {
    if (!isCompleted || scoredMarks == null) return 0.0;
    return (scoredMarks! / maxMarks) * weight;
  }

  double get _rawPredictedScaledScore {
    final double marks = isCompleted ? (scoredMarks ?? 0.0) : predictedMarks;
    return (marks / maxMarks) * weight;
  }

  double get _rawMaxPossibleScaledScore {
    if (isCompleted && scoredMarks != null) {
      return _rawCurrentScaledScore;
    }
    return weight;
  }

  double get _rawMinPossibleScaledScore {
    if (isCompleted && scoredMarks != null) {
      return _rawCurrentScaledScore;
    }
    return 0.0;
  }

  // --- RECURSIVE GETTERS FOR COMPONENT SCORES ---

  double get currentScaledScore {
    if (type == 'standalone') {
      return _rawCurrentScaledScore;
    }
    // Grouped component
    final childScores = children.map((c) => c.currentScaledScore).toList();
    return _applySelectionRule(childScores);
  }

  double get predictedScaledScore {
    if (type == 'standalone') {
      return _rawPredictedScaledScore;
    }
    // Grouped component
    final childScores = children.map((c) => c.predictedScaledScore).toList();
    return _applySelectionRule(childScores);
  }

  double get maxPossibleScaledScore {
    if (type == 'standalone') {
      return _rawMaxPossibleScaledScore;
    }
    // Grouped component
    final childScores = children.map((c) => c.maxPossibleScaledScore).toList();
    return _applySelectionRule(childScores);
  }

  double get minPossibleScaledScore {
    if (type == 'standalone') {
      return _rawMinPossibleScaledScore;
    }
    // Grouped component
    final childScores = children.map((c) => c.minPossibleScaledScore).toList();
    return _applySelectionRule(childScores);
  }

  double _applySelectionRule(List<double> scores) {
    if (scores.isEmpty) return 0.0;
    if (selectionRule == 'sum_all') {
      return scores.fold(0.0, (sum, score) => sum + score);
    }
    
    // Parse best K
    int k = 1;
    if (selectionRule == 'best_1') k = 1;
    else if (selectionRule == 'best_2') k = 2;
    else if (selectionRule == 'best_3') k = 3;

    final sorted = List<double>.from(scores)..sort();
    double total = 0.0;
    for (int i = 0; i < k && i < sorted.length; i++) {
      total += sorted[sorted.length - 1 - i];
    }
    return total;
  }

  GenericComponent copyWith({
    String? id,
    String? name,
    String? type,
    double? maxMarks,
    double? weight,
    double? scoredMarks,
    double? predictedMarks,
    bool? isCompleted,
    List<GenericComponent>? children,
    String? selectionRule,
    bool clearScoredMarks = false,
  }) {
    return GenericComponent(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      maxMarks: maxMarks ?? this.maxMarks,
      weight: weight ?? this._weight,
      scoredMarks: clearScoredMarks ? null : (scoredMarks ?? this.scoredMarks),
      predictedMarks: predictedMarks ?? this.predictedMarks,
      isCompleted: isCompleted ?? this.isCompleted,
      children: children ?? this.children,
      selectionRule: selectionRule ?? this.selectionRule,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'maxMarks': maxMarks,
      'weight': weight,
      'scoredMarks': scoredMarks,
      'predictedMarks': predictedMarks,
      'isCompleted': isCompleted,
      'children': children.map((x) => x.toMap()).toList(),
      'selectionRule': selectionRule,
    };
  }

  factory GenericComponent.fromMap(Map<String, dynamic> map) {
    return GenericComponent(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      type: map['type'] ?? 'standalone',
      maxMarks: (map['maxMarks'] as num?)?.toDouble() ?? 100.0,
      weight: (map['weight'] as num?)?.toDouble() ?? 100.0,
      scoredMarks: map['scoredMarks'] != null ? (map['scoredMarks'] as num).toDouble() : null,
      predictedMarks: (map['predictedMarks'] as num?)?.toDouble() ?? 0.0,
      isCompleted: map['isCompleted'] ?? false,
      children: List<GenericComponent>.from(
        map['children']?.map((x) => GenericComponent.fromMap(x)) ?? const [],
      ),
      selectionRule: map['selectionRule'] ?? 'sum_all',
    );
  }

  String toJson() => json.encode(toMap());

  factory GenericComponent.fromJson(String source) => GenericComponent.fromMap(json.decode(source));
}
