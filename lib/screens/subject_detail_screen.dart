import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../models/subject.dart';
import '../models/subject_type.dart';
import '../models/assessment_component.dart';
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
          final textTint = AppTheme.subjectTextColor(subject.code);
          final bgTint = AppTheme.subjectBgColor(subject.code);

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
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
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
                          '${subject.assessments.length} Items',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: textTint,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // 4. List of Assessment Adjusters
                  ...subject.assessments.map((a) => AssessmentAdjusterWidget(
                        provider: provider,
                        subjectCode: subject.code,
                        assessment: a,
                        activeColor: textTint,
                        bgTint: bgTint,
                      )),
                  
                  // 5. Grade Point Loss Analysis
                  _buildGradePointLossAnalysis(context, subject, provider, textTint, bgTint),
                  const SizedBox(height: 40),
                ],
              ),
            ),
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
          // Left details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PREDICTED TOTAL MARKS',
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
                  'Credits: ${subject.credits} | Type: ${subject.type.displayName}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textColorSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Right Grade Badge (Soft Circle/Pill Badge)
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
          
          // M3 clean linear bounds bar
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
              _buildStatIndicator('Floor (Min)', subject.minPossibleScore.toStringAsFixed(1), activeColor.withOpacity(0.4)),
              _buildStatIndicator('Simulated', subject.predictedScore.toStringAsFixed(1), activeColor),
              _buildStatIndicator('Ceiling (Max)', subject.maxPossibleScore.toStringAsFixed(1), activeColor.withOpacity(0.8)),
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
    const int totalSemCredits = 22;
    
    // Subject credit-weighted calculations relative to the 10.0 SGPA scale:
    final double maxSgpaContribution = (subject.credits * 10.0) / totalSemCredits;
    final double sgpaPointsLost = (subject.credits / totalSemCredits) * (subject.marksPermanentlyLost / 10.0);
    final double sgpaPointsPredicted = (subject.credits / totalSemCredits) * (subject.predictedScore / 10.0);
    final double maxAchievableSgpaContribution = (subject.credits / totalSemCredits) * (subject.maxPossibleScore / 10.0);
    
    final String predictedGrade = subject.getPredictedGradeLetter(provider.gradeScheme);
    final int predictedGradePoints = subject.getPredictedGradePoints(provider.gradeScheme);

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
              // Header Summary: Predicted SGPA Contribution & Continuous GPA
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PREDICTED SGPA CONTRIBUTION',
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
              
              // Divider line
              Container(
                height: 1.0,
                color: AppTheme.borderColor,
                margin: const EdgeInsets.only(bottom: 18),
              ),

              // Analysis Metrics Grid
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // SGPA Contribution Lost
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
                          '(${subject.marksPermanentlyLost.toStringAsFixed(1)} marks lost)',
                          style: TextStyle(
                            fontSize: 8,
                            color: AppTheme.textColorSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Remaining SGPA Contribution
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
                          '(${subject.maxPossibleScore.toStringAsFixed(1)}% achievable)',
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
                  // Max marks still achievable
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Subject Max Achievable',
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
                  // Predicted Subject Score & Grade points
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Predicted Score & GP',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textColorSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${subject.predictedScore.toStringAsFixed(1)}% ($predictedGradePoints GP)',
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
              
              // Warning text if loss > 0
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
}

class AssessmentAdjusterWidget extends StatefulWidget {
  final AcademicProvider provider;
  final String subjectCode;
  final AssessmentComponent assessment;
  final Color activeColor;
  final Color bgTint;

  const AssessmentAdjusterWidget({
    super.key,
    required this.provider,
    required this.subjectCode,
    required this.assessment,
    required this.activeColor,
    required this.bgTint,
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
    final double currentValue = widget.assessment.isCompleted
        ? (widget.assessment.scoredMarks ?? 0.0)
        : widget.assessment.predictedMarks;

    final double scaledScore = widget.assessment.isCompleted
        ? widget.assessment.currentScaledScore
        : widget.assessment.predictedScaledScore;

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Row Header
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
                
                // M3 Status Toggle Chip
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
              ],
            ),
            
            const SizedBox(height: 14),

            // Clean M3 Slider with Haptic Vibration & 0.05 step snapping
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
                      divisions: widget.assessment.maxMarks.round(),
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
                
                // Keyboard Input Box & Scaled Point Display
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
        ),
      ),
    );
  }
}
