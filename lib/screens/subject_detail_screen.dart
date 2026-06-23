import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../models/subject.dart';
import '../models/generic_component.dart';
import '../services/academic_provider.dart';
import '../widgets/glass_card.dart';
import '../widgets/mesh_gradient_background.dart';

class SubjectDetailScreen extends StatelessWidget {
  final String subjectCode;

  const SubjectDetailScreen({super.key, required this.subjectCode});

  @override
  Widget build(BuildContext context) {
    return MeshGradientBackground(
      child: Consumer<AcademicProvider>(
        builder: (context, provider, child) {
          final subjectIndex = provider.subjects.indexWhere((s) => s.code == subjectCode);
          if (subjectIndex == -1) {
            return Scaffold(
              backgroundColor: Colors.transparent,
              body: Center(
                child: Text('Course not found: $subjectCode'),
              ),
            );
          }

          final subject = provider.subjects[subjectIndex];
          final textTint = AppTheme.subjectTextColor(subject.code, subject.name);
          final bgTint = AppTheme.subjectBgColor(subject.code, subject.name);

          return GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              FocusManager.instance.primaryFocus?.unfocus();
            },
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: Icon(Icons.arrow_back, color: AppTheme.textColorPrimary),
                  onPressed: () {
                    FocusManager.instance.primaryFocus?.unfocus();
                    Navigator.pop(context);
                  },
                ),
                title: Text(
                  subject.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: AppTheme.textColorPrimary,
                  ),
                ),
                centerTitle: true,
              ),
              body: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 20.0, bottom: 100.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Top Hero Card
                    _buildHeroScoreCard(context, subject, bgTint, textTint),
                    const SizedBox(height: 20),

                    // 2. Score Range Bounds Meter
                    _buildRangeMeter(context, subject, textTint),
                    const SizedBox(height: 28),

                    // 3. Components Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Assessment Components',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textColorPrimary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: bgTint,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${subject.components.length} Items',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: textTint,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    if (provider.isConfigMode) ...[
                      const SizedBox(height: 12),
                      Text(
                        '💡 Long press to reorder components',
                        style: TextStyle(
                          fontSize: 9,
                          color: AppTheme.textColorSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),

                    // 4. List of Assessment Adjusters
                    if (provider.isConfigMode)
                      Theme(
                        data: Theme.of(context).copyWith(
                          canvasColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                        ),
                        child: ReorderableListView(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          onReorder: (oldIndex, newIndex) {
                            provider.reorderComponents(subject.code, oldIndex, newIndex);
                          },
                          children: [
                            for (int idx = 0; idx < subject.components.length; idx++)
                              KeyedSubtree(
                                key: ValueKey(subject.components[idx].id),
                                child: AssessmentAdjusterWidget(
                                  provider: provider,
                                  subjectCode: subject.code,
                                  assessment: subject.components[idx],
                                  activeColor: textTint,
                                  bgTint: bgTint,
                                  onEdit: () => _showComponentDialog(context, provider, subject.code, subject.components[idx]),
                                  onDelete: () => _confirmDelete(context, provider, subject.code, subject.components[idx]),
                                ),
                              ),
                          ],
                        ),
                      )
                    else
                      Column(
                        children: [
                          for (int idx = 0; idx < subject.components.length; idx++)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: AssessmentAdjusterWidget(
                                provider: provider,
                                subjectCode: subject.code,
                                assessment: subject.components[idx],
                                activeColor: textTint,
                                bgTint: bgTint,
                              ),
                            ),
                        ],
                      ),
                    
                    // 5. Grade Point Loss Analysis
                    _buildGradePointLossAnalysis(context, subject, provider, textTint, bgTint),
                  ],
                ),
              ),
              bottomNavigationBar: provider.isConfigMode ? _buildConfigBottomBar(context, provider) : null,
              floatingActionButton: provider.isConfigMode
                  ? FloatingActionButton.extended(
                      onPressed: () => _showComponentDialog(context, provider, subject.code, null),
                      backgroundColor: textTint,
                      foregroundColor: Colors.white,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Component'),
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeroScoreCard(BuildContext context, Subject subject, Color bgTint, Color textTint) {
    return GlassCard(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'YOUR CURRENT SCORE',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textColorSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      subject.predictedScore.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textColorPrimary,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '/ 100',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textColorSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Credits: ${subject.credits}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textColorSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Right Grade Badge
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: bgTint,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    subject.predictedGradeLetter,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: textTint,
                    ),
                  ),
                  Text(
                    'GP: ${subject.predictedGradePoints}',
                    style: TextStyle(
                      fontSize: 9,
                      color: textTint.withOpacity(0.8),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRangeMeter(BuildContext context, Subject subject, Color activeColor) {
    final double minRatio = (subject.minPossibleScore / 100.0).clamp(0.0, 1.0);
    final double maxRatio = (subject.maxPossibleScore / 100.0).clamp(0.0, 1.0);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Performance Bounds',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColorSecondary,
                  fontSize: 11,
                ),
              ),
              if (subject.marksPermanentlyLost > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.accentRed.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Lost: ${subject.marksPermanentlyLost.toStringAsFixed(1)} pts',
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.accentRed,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: AppTheme.borderColor.withOpacity(0.4),
              borderRadius: BorderRadius.circular(4),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Stack(
                children: [
                  FractionallySizedBox(
                    widthFactor: maxRatio,
                    child: Container(
                      color: activeColor.withOpacity(0.24),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: minRatio,
                    child: Container(
                      color: activeColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatIndicator('Worst Case', subject.minPossibleScore.toStringAsFixed(1), activeColor.withOpacity(0.4)),
              _buildStatIndicator('Current Score', subject.predictedScore.toStringAsFixed(1), activeColor),
              _buildStatIndicator('Best Case', subject.maxPossibleScore.toStringAsFixed(1), activeColor.withOpacity(0.8)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatIndicator(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: AppTheme.textColorSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textColorPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildGradePointLossAnalysis(
    BuildContext context,
    Subject subject,
    AcademicProvider provider,
    Color activeColor,
    Color bgTint,
  ) {
    final int totalSemCredits = provider.sem4TotalCredits;
    
    final int predictedGp = subject.getPredictedGradePoints(provider.gradeScheme);
    final int maxGp = provider.gradeScheme.getBoundary(subject.maxPossibleScore).gradePoints;
    final double maxSgpaContribution = (subject.credits * 10.0) / totalSemCredits;
    final double sgpaPointsPredicted = (subject.credits.toDouble() / totalSemCredits) * predictedGp;
    final double maxAchievableSgpaContribution = (subject.credits.toDouble() / totalSemCredits) * maxGp;
    final double sgpaPointsLost = maxSgpaContribution - maxAchievableSgpaContribution;
    
    final String predictedGrade = subject.getPredictedGradeLetter(provider.gradeScheme);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),
        Row(
          children: [
            Icon(Icons.analytics_rounded, color: activeColor, size: 20),
            const SizedBox(width: 8),
            Text(
              'SGPA Impact & Loss Analysis',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.textColorPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'YOUR SGPA CONTRIBUTION',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textColorSecondary,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            sgpaPointsPredicted.toStringAsFixed(3),
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textColorPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            ' / ${maxSgpaContribution.toStringAsFixed(3)} GP',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textColorSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: bgTint,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      predictedGrade,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: activeColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              
              Container(
                height: 1.0,
                color: AppTheme.borderColor,
                margin: const EdgeInsets.only(bottom: 18),
              ),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SGPA Points Lost',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textColorSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '-${sgpaPointsLost.toStringAsFixed(3)} GP',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: sgpaPointsLost > 0.0 ? AppTheme.accentRed : AppTheme.textColorPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '(${subject.marksPermanentlyLost.toStringAsFixed(1)} marks already gone)',
                          style: TextStyle(
                            fontSize: 8,
                            color: AppTheme.textColorSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Max SGPA Contribution',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textColorSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${maxAchievableSgpaContribution.toStringAsFixed(3)} GP',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textColorPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '(${subject.maxPossibleScore.toStringAsFixed(1)}% still possible)',
                          style: TextStyle(
                            fontSize: 8,
                            color: AppTheme.textColorSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Best Score Still Possible',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textColorSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${subject.maxPossibleScore.toStringAsFixed(1)} / 100',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textColorPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Score & Grade Points',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textColorSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${subject.predictedScore.toStringAsFixed(1)}% (${subject.predictedGradePoints} GP)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textColorPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              if (sgpaPointsLost > 0.0) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.accentRed.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.accentRed.withOpacity(0.12),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: AppTheme.accentRed, size: 14),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'A perfect SGPA contribution is no longer possible. You have permanently lost ${sgpaPointsLost.toStringAsFixed(3)} grade points on your overall Semester SGPA from this course.',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                            height: 1.3,
                            color: AppTheme.accentRed.withOpacity(0.9),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  void _showComponentDialog(BuildContext context, AcademicProvider provider, String subjectCode, GenericComponent? existingComponent) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ComponentDialog(
        provider: provider,
        subjectCode: subjectCode,
        existingComponent: existingComponent,
      ),
    );
  }

  void _confirmDelete(BuildContext context, AcademicProvider provider, String subjectCode, GenericComponent component) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: Text('Delete Component', style: TextStyle(color: AppTheme.textColorPrimary)),
        content: Text('Are you sure you want to delete "${component.name}"? This cannot be undone.', style: TextStyle(color: AppTheme.textColorSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.deleteComponent(subjectCode, component.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentRed, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // --- CONFIGURATION MODE HELPERS ---

  Widget _buildConfigBottomBar(BuildContext context, AcademicProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        border: Border(
          top: BorderSide(color: AppTheme.borderColor.withOpacity(0.5)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => _confirmDiscardChanges(context, provider),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: AppTheme.borderColor),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: AppTheme.textColorSecondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: () => _saveDraftConfig(context, provider),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Text(
                'Save Changes',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDiscardChanges(BuildContext context, AcademicProvider provider) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Discard Changes?', style: TextStyle(color: AppTheme.textColorPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to discard all structural changes? This cannot be undone.', style: TextStyle(color: AppTheme.textColorSecondary, fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Keep Editing')),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              provider.cancelConfigurationMode();
            },
            child: const Text('Discard', style: TextStyle(color: AppTheme.accentRed)),
          ),
        ],
      ),
    );
  }

  void _saveDraftConfig(BuildContext context, AcademicProvider provider) {
    final errors = provider.saveConfigurationMode();
    if (errors.isNotEmpty) {
      _showValidationAlert(context, errors);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semester configuration saved!'), backgroundColor: AppTheme.accentTeal),
      );
    }
  }

  void _showValidationAlert(BuildContext context, List<String> errors) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          const Icon(Icons.warning_amber_rounded, color: AppTheme.accentRed),
          const SizedBox(width: 8),
          Text('Invalid Structure', style: TextStyle(color: AppTheme.textColorPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
        ]),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: errors.map((err) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• ', style: TextStyle(color: AppTheme.textColorPrimary, fontWeight: FontWeight.bold)),
                  Expanded(child: Text(err, style: TextStyle(color: AppTheme.textColorSecondary, fontSize: 12))),
                ],
              ),
            )).toList(),
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('OK'))],
      ),
    );
  }
}

class AssessmentAdjusterWidget extends StatefulWidget {
  final AcademicProvider provider;
  final String subjectCode;
  final GenericComponent assessment;
  final Color activeColor;
  final Color bgTint;
  final bool isChildMode;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const AssessmentAdjusterWidget({
    super.key,
    required this.provider,
    required this.subjectCode,
    required this.assessment,
    required this.activeColor,
    required this.bgTint,
    this.isChildMode = false,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<AssessmentAdjusterWidget> createState() => _AssessmentAdjusterWidgetState();
}

class _AssessmentAdjusterWidgetState extends State<AssessmentAdjusterWidget> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  double _lastHapticValue = -1.0;

  @override
  void initState() {
    super.initState();
    final double currentValue = widget.assessment.isCompleted
        ? (widget.assessment.scoredMarks ?? 0.0)
        : widget.assessment.predictedMarks;
    _controller = TextEditingController(
      text: currentValue == currentValue.roundToDouble()
          ? currentValue.toStringAsFixed(0)
          : currentValue.toStringAsFixed(2),
    );
    _focusNode = FocusNode();
    
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        _submitValue(_controller.text);
      }
    });
  }

  @override
  void didUpdateWidget(covariant AssessmentAdjusterWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focusNode.hasFocus) {
      final double currentValue = widget.assessment.isCompleted
          ? (widget.assessment.scoredMarks ?? 0.0)
          : widget.assessment.predictedMarks;
      final formatted = currentValue == currentValue.roundToDouble()
          ? currentValue.toStringAsFixed(0)
          : currentValue.toStringAsFixed(2);
      if (_controller.text != formatted) {
        _controller.text = formatted;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submitValue(String text) {
    final parsed = double.tryParse(text);
    if (parsed != null) {
      final clamped = parsed.clamp(0.0, widget.assessment.maxMarks);
      final finalValue = double.parse(clamped.toStringAsFixed(2));
      
      widget.provider.updateAssessment(
        subjectCode: widget.subjectCode,
        assessmentId: widget.assessment.id,
        isCompleted: widget.assessment.isCompleted,
        scoredMarks: widget.assessment.isCompleted ? finalValue : null,
        predictedMarks: finalValue,
        saveToDisk: true,
      );
      
      _controller.text = finalValue == finalValue.roundToDouble()
          ? finalValue.toStringAsFixed(0)
          : finalValue.toStringAsFixed(2);
    }
  }

  @override
  Widget build(BuildContext context) {
    // If it's a Grouped Component and we are NOT in child mode, render the Parent Card holding children recursively!
    if (widget.assessment.type == 'grouped' && !widget.isChildMode) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16.0),
        child: GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Group Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.assessment.name,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textColorPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Group: ${widget.assessment.selectionRule.toUpperCase().replaceAll("_", " ")} | Weight: ${widget.assessment.weight.toStringAsFixed(0)} pts',
                          style: TextStyle(
                            fontSize: 9,
                            color: AppTheme.textColorSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Edit / Delete Actions
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.onEdit != null)
                        IconButton(
                          icon: Icon(Icons.edit_outlined, size: 16, color: AppTheme.textColorSecondary),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: widget.onEdit,
                        ),
                      if (widget.onEdit != null) const SizedBox(width: 10),
                      if (widget.onDelete != null)
                        IconButton(
                          icon: Icon(Icons.delete_outline_rounded, size: 16, color: AppTheme.accentRed.withOpacity(0.8)),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: widget.onDelete,
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Children adjusters list (Child mode renders them compactly without glass card wrappers)
              ...widget.assessment.children.map((child) => Container(
                margin: const EdgeInsets.only(top: 8.0),
                decoration: BoxDecoration(
                  color: AppTheme.isDark ? Colors.black.withOpacity(0.1) : Colors.black.withOpacity(0.02),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: AssessmentAdjusterWidget(
                  provider: widget.provider,
                  subjectCode: widget.subjectCode,
                  assessment: child,
                  activeColor: widget.activeColor,
                  bgTint: widget.bgTint,
                  isChildMode: true,
                ),
              )),
            ],
          ),
        ),
      );
    }

    // Otherwise, render a Standalone Adjuster Row (either as a top-level GlassCard or in child mode inside a Group)
    final double currentValue = widget.assessment.isCompleted
        ? (widget.assessment.scoredMarks ?? 0.0)
        : widget.assessment.predictedMarks;

    final double scaledScore = widget.assessment.isCompleted
        ? widget.assessment.currentScaledScore
        : widget.assessment.predictedScaledScore;

    Widget adjusterContent = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.assessment.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textColorPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Weight: ${widget.assessment.weight.toStringAsFixed(0)} pts (${widget.assessment.maxMarks.toStringAsFixed(0)} max marks)',
                    style: TextStyle(
                      fontSize: 9,
                      color: AppTheme.textColorSecondary,
                    ),
                  ),
                ],
              ),
            ),
            
            // Completed / Pending Status Chip
            GestureDetector(
              onTap: () {
                widget.provider.updateAssessment(
                  subjectCode: widget.subjectCode,
                  assessmentId: widget.assessment.id,
                  isCompleted: !widget.assessment.isCompleted,
                  scoredMarks: !widget.assessment.isCompleted ? currentValue : null,
                  predictedMarks: currentValue,
                );
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.assessment.isCompleted ? widget.activeColor.withOpacity(0.08) : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: widget.assessment.isCompleted ? widget.activeColor : AppTheme.borderColor,
                    width: 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.assessment.isCompleted ? Icons.check_circle_outline_rounded : Icons.radio_button_off_rounded,
                      size: 12,
                      color: widget.assessment.isCompleted ? widget.activeColor : AppTheme.textColorSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.assessment.isCompleted ? 'Completed' : 'Pending',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: widget.assessment.isCompleted ? widget.activeColor : AppTheme.textColorSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Add Edit / Delete icons if not child mode and callbacks are provided
            if (!widget.isChildMode && widget.onEdit != null && widget.onDelete != null) ...[
              const SizedBox(width: 10),
              IconButton(
                icon: Icon(Icons.edit_outlined, size: 16, color: AppTheme.textColorSecondary),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: widget.onEdit,
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.delete_outline_rounded, size: 16, color: AppTheme.accentRed.withOpacity(0.8)),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: widget.onDelete,
              ),
            ],
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: widget.activeColor,
                  inactiveTrackColor: widget.activeColor.withOpacity(0.12),
                  thumbColor: widget.activeColor,
                  overlayColor: widget.activeColor.withOpacity(0.12),
                  trackHeight: 6,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 10.0,
                  ),
                ),
                child: Slider(
                  value: currentValue.roundToDouble().clamp(0.0, widget.assessment.maxMarks),
                  min: 0.0,
                  max: widget.assessment.maxMarks,
                  divisions: widget.assessment.maxMarks.round() > 0 ? widget.assessment.maxMarks.round() : 1,
                  label: currentValue.roundToDouble().toStringAsFixed(0),
                  onChanged: (newValue) {
                    final finalValue = newValue.roundToDouble().clamp(0.0, widget.assessment.maxMarks);
                    
                    if (finalValue != _lastHapticValue) {
                      HapticFeedback.selectionClick();
                      _lastHapticValue = finalValue;
                    }

                    if (_focusNode.hasFocus) {
                      _focusNode.unfocus();
                    }

                    _controller.text = finalValue.toStringAsFixed(0);

                    widget.provider.updateAssessment(
                      subjectCode: widget.subjectCode,
                      assessmentId: widget.assessment.id,
                      isCompleted: widget.assessment.isCompleted,
                      scoredMarks: widget.assessment.isCompleted ? finalValue : null,
                      predictedMarks: finalValue,
                      saveToDisk: false,
                    );
                  },
                  onChangeEnd: (newValue) {
                    final finalValue = newValue.roundToDouble().clamp(0.0, widget.assessment.maxMarks);
                    
                    widget.provider.updateAssessment(
                      subjectCode: widget.subjectCode,
                      assessmentId: widget.assessment.id,
                      isCompleted: widget.assessment.isCompleted,
                      scoredMarks: widget.assessment.isCompleted ? finalValue : null,
                      predictedMarks: finalValue,
                      saveToDisk: true,
                    );
                  },
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  width: 84,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppTheme.bgColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _focusNode.hasFocus ? widget.activeColor : AppTheme.borderColor,
                      width: _focusNode.hasFocus ? 1.5 : 1.0,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textColorPrimary,
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                    ),
                    onChanged: (text) {
                      final parsed = double.tryParse(text);
                      if (parsed != null) {
                        final clamped = parsed.clamp(0.0, widget.assessment.maxMarks);
                        widget.provider.updateAssessment(
                            subjectCode: widget.subjectCode,
                            assessmentId: widget.assessment.id,
                            isCompleted: widget.assessment.isCompleted,
                            scoredMarks: widget.assessment.isCompleted ? clamped : null,
                            predictedMarks: clamped,
                            saveToDisk: false,
                        );
                      }
                    },
                    onSubmitted: (text) {
                      _submitValue(text);
                      _focusNode.unfocus();
                    },
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${scaledScore.toStringAsFixed(2)} pts',
                  style: TextStyle(
                    fontSize: 8,
                    color: AppTheme.textColorSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );

    if (widget.isChildMode) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: adjusterContent,
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 18.0),
        child: adjusterContent,
      ),
    );
  }
}

class ComponentDialog extends StatefulWidget {
  final AcademicProvider provider;
  final String subjectCode;
  final GenericComponent? existingComponent;

  const ComponentDialog({
    super.key,
    required this.provider,
    required this.subjectCode,
    this.existingComponent,
  });

  @override
  State<ComponentDialog> createState() => _ComponentDialogState();
}

class _ComponentDialogState extends State<ComponentDialog> {
  late String _type; // "standalone" or "grouped"
  late TextEditingController _nameController;
  late TextEditingController _maxMarksController;
  late TextEditingController _weightController;
  late String _selectionRule;
  late List<GenericComponent> _children;
  String _selectedPreset = 'Custom';

  final List<String> _presets = [
    'CIE', 'Quiz', 'Assignment', 'Lab', 'Viva', 'SEE', 'Project', 'AAT', 'Internal', 'Custom'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existingComponent != null) {
      final comp = widget.existingComponent!;
      _type = comp.type;
      _nameController = TextEditingController(text: comp.name);
      _maxMarksController = TextEditingController(text: comp.maxMarks.toStringAsFixed(0));
      _weightController = TextEditingController(text: comp.weight.toStringAsFixed(0));
      _selectionRule = comp.selectionRule;
      _children = List<GenericComponent>.from(comp.children);
    } else {
      _type = 'standalone';
      _nameController = TextEditingController();
      _maxMarksController = TextEditingController(text: '100');
      _weightController = TextEditingController(text: '100');
      _selectionRule = 'sum_all';
      _children = [];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _maxMarksController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _applyPreset(String preset) {
    setState(() {
      _selectedPreset = preset;
      if (preset == 'CIE') {
        _type = 'grouped';
        _nameController.text = 'CIE';
        _selectionRule = 'best_2';
        
        final double marks = 20.0;
        
        _children = [
          GenericComponent(id: 'cie1_${DateTime.now().millisecondsSinceEpoch}', name: 'CIE 1', type: 'standalone', maxMarks: marks, weight: marks),
          GenericComponent(id: 'cie2_${DateTime.now().millisecondsSinceEpoch + 1}', name: 'CIE 2', type: 'standalone', maxMarks: marks, weight: marks),
          GenericComponent(id: 'cie3_${DateTime.now().millisecondsSinceEpoch + 2}', name: 'CIE 3', type: 'standalone', maxMarks: marks, weight: marks),
        ];
      } else {
        _type = 'standalone';
        _nameController.text = preset == 'Custom' ? '' : preset;
        if (preset == 'Quiz') {
          _maxMarksController.text = '10';
          _weightController.text = '10';
        } else if (preset == 'Assignment') {
          _maxMarksController.text = '10';
          _weightController.text = '10';
        } else if (preset == 'Lab') {
          _nameController.text = 'Lab Internal';
          _maxMarksController.text = '25';
          _weightController.text = '25';
        } else if (preset == 'Viva') {
          _maxMarksController.text = '10';
          _weightController.text = '10';
        } else if (preset == 'SEE') {
          _nameController.text = 'Semester End Exam';
          _maxMarksController.text = '100';
          _weightController.text = '50';
        } else if (preset == 'Project') {
          _maxMarksController.text = '50';
          _weightController.text = '50';
        } else if (preset == 'AAT') {
          _maxMarksController.text = '5';
          _weightController.text = '5';
        } else if (preset == 'Internal') {
          _maxMarksController.text = '50';
          _weightController.text = '50';
        } else {
          _maxMarksController.text = '100';
          _weightController.text = '100';
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 450),
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.existingComponent == null ? 'Add Component' : 'Edit Component',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColorPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _type = 'standalone';
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _type == 'standalone' ? AppTheme.primaryBlue : AppTheme.borderColor.withOpacity(0.2),
                        foregroundColor: _type == 'standalone' ? Colors.white : AppTheme.textColorPrimary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Standalone', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _type = 'grouped';
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _type == 'grouped' ? AppTheme.primaryBlue : AppTheme.borderColor.withOpacity(0.2),
                        foregroundColor: _type == 'grouped' ? Colors.white : AppTheme.textColorPrimary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Grouped', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Text(
                'PRESETS',
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.textColorSecondary),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _presets.map((preset) {
                    final isSelected = _selectedPreset == preset;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6.0),
                      child: ChoiceChip(
                        label: Text(preset, style: const TextStyle(fontSize: 10)),
                        selected: isSelected,
                        onSelected: (_) => _applyPreset(preset),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _nameController,
                style: TextStyle(color: AppTheme.textColorPrimary),
                decoration: InputDecoration(
                  labelText: 'Component Name',
                  labelStyle: TextStyle(color: AppTheme.textColorSecondary),
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 16),

              if (_type == 'standalone') ...[
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _maxMarksController,
                        style: TextStyle(color: AppTheme.textColorPrimary),
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Max Marks',
                          labelStyle: TextStyle(color: AppTheme.textColorSecondary),
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _weightController,
                        style: TextStyle(color: AppTheme.textColorPrimary),
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Weight',
                          labelStyle: TextStyle(color: AppTheme.textColorSecondary),
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                DropdownButtonFormField<String>(
                  value: _selectionRule,
                  dropdownColor: AppTheme.cardColor,
                  style: TextStyle(color: AppTheme.textColorPrimary),
                  decoration: InputDecoration(
                    labelText: 'Selection Rule',
                    labelStyle: TextStyle(color: AppTheme.textColorSecondary),
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'sum_all', child: Text('Sum All')),
                    DropdownMenuItem(value: 'best_1', child: Text('Best 1')),
                    DropdownMenuItem(value: 'best_2', child: Text('Best 2')),
                    DropdownMenuItem(value: 'best_3', child: Text('Best 3')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectionRule = val;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'CHILD ASSESSMENTS',
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.textColorSecondary),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _children.add(
                            GenericComponent(
                              id: 'child_${DateTime.now().millisecondsSinceEpoch}_${_children.length}',
                              name: 'Child ${_children.length + 1}',
                              type: 'standalone',
                              maxMarks: 10,
                              weight: 10,
                            ),
                          );
                        });
                      },
                      icon: const Icon(Icons.add, size: 12),
                      label: const Text('Add Child', style: TextStyle(fontSize: 10)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...List.generate(_children.length, (idx) {
                  final child = _children[idx];
                  return Padding(
                    key: ValueKey(child.id),
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            initialValue: child.name,
                            style: TextStyle(color: AppTheme.textColorPrimary, fontSize: 11),
                            decoration: const InputDecoration(
                              labelText: 'Name',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            ),
                            onChanged: (val) {
                              _children[idx] = child.copyWith(name: val);
                            },
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: TextFormField(
                            initialValue: child.maxMarks.toStringAsFixed(0),
                            style: TextStyle(color: AppTheme.textColorPrimary, fontSize: 11),
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Max',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            ),
                            onChanged: (val) {
                              final parsed = double.tryParse(val) ?? 10;
                              _children[idx] = child.copyWith(maxMarks: parsed, weight: parsed);
                            },
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.remove_circle_outline, color: AppTheme.accentRed.withOpacity(0.8), size: 18),
                          onPressed: () {
                            setState(() {
                              _children.removeAt(idx);
                            });
                          },
                        ),
                      ],
                    ),
                  );
                }),
              ],
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      final name = _nameController.text.trim();
                      if (name.isEmpty) return;

                      GenericComponent comp;
                      if (_type == 'standalone') {
                        final maxMarks = double.tryParse(_maxMarksController.text) ?? 100.0;
                        final weight = double.tryParse(_weightController.text) ?? 100.0;
                        comp = GenericComponent(
                          id: widget.existingComponent?.id ?? 'standalone_${DateTime.now().millisecondsSinceEpoch}',
                          name: name,
                          type: 'standalone',
                          maxMarks: maxMarks,
                          weight: weight,
                          scoredMarks: widget.existingComponent?.scoredMarks,
                          predictedMarks: widget.existingComponent?.predictedMarks ?? 0.0,
                          isCompleted: widget.existingComponent?.isCompleted ?? false,
                        );
                      } else {
                        double calculatedWeight = 0.0;
                        final childScores = _children.map((c) => c.weight).toList();
                        if (_selectionRule == 'sum_all') {
                          calculatedWeight = childScores.fold(0.0, (s, w) => s + w);
                        } else {
                          int k = 1;
                          if (_selectionRule == 'best_1') k = 1;
                          else if (_selectionRule == 'best_2') k = 2;
                          else if (_selectionRule == 'best_3') k = 3;
                          final sorted = List<double>.from(childScores)..sort();
                          for (int i = 0; i < k && i < sorted.length; i++) {
                            calculatedWeight += sorted[sorted.length - 1 - i];
                          }
                        }

                        comp = GenericComponent(
                          id: widget.existingComponent?.id ?? 'grouped_${DateTime.now().millisecondsSinceEpoch}',
                          name: name,
                          type: 'grouped',
                          weight: calculatedWeight,
                          selectionRule: _selectionRule,
                          children: _children,
                        );
                      }

                      if (widget.existingComponent != null) {
                        widget.provider.updateComponent(widget.subjectCode, comp);
                      } else {
                        widget.provider.addComponent(widget.subjectCode, comp);
                      }
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
