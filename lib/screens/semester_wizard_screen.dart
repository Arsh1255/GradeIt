import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../models/semester.dart';
import '../models/subject.dart';
import '../models/generic_component.dart';
import '../models/grade_scheme.dart';
import '../services/academic_provider.dart';
import '../widgets/glass_card.dart';
import '../widgets/mesh_gradient_background.dart';

class SemesterWizardScreen extends StatefulWidget {
  const SemesterWizardScreen({super.key});

  @override
  State<SemesterWizardScreen> createState() => _SemesterWizardScreenState();
}

class _SemesterWizardScreenState extends State<SemesterWizardScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // --- Step 1 States (Semester Details) ---
  final _semNameController = TextEditingController(text: 'My Semester');
  final _collegeController = TextEditingController();
  final _branchController = TextEditingController();
  String _gradeSchemePreset = 'BMSCE'; // BMSCE, VTU, Custom
  bool _isInclusiveBoundaries = true;
  List<GradeBoundary> _customBoundaries = [
    const GradeBoundary(minMarks: 90.0, maxMarks: 100.0, gradeLetter: 'S', gradePoints: 10),
    const GradeBoundary(minMarks: 80.0, maxMarks: 89.9, gradeLetter: 'A', gradePoints: 9),
    const GradeBoundary(minMarks: 70.0, maxMarks: 79.9, gradeLetter: 'B', gradePoints: 8),
    const GradeBoundary(minMarks: 60.0, maxMarks: 69.9, gradeLetter: 'C', gradePoints: 7),
    const GradeBoundary(minMarks: 50.0, maxMarks: 59.9, gradeLetter: 'D', gradePoints: 6),
    const GradeBoundary(minMarks: 40.0, maxMarks: 49.9, gradeLetter: 'E', gradePoints: 4),
    const GradeBoundary(minMarks: 0.0, maxMarks: 39.9, gradeLetter: 'F', gradePoints: 0),
  ];

  // --- Step 2 States (Subjects) ---
  final List<Subject> _subjects = [];
  final _subNameController = TextEditingController();
  final _subCodeController = TextEditingController();
  final _subCreditsController = TextEditingController(text: '4');

  // --- Step 3 States (Component Setup) ---
  // Tracks selected templates for each subject: 'integrated', 'theoryA', 'theoryB', 'practical', 'external', 'custom'
  final Map<String, String> _subjectTemplates = {}; 
  // Custom component lists for subjects where template == 'custom'
  final Map<String, List<GenericComponent>> _subjectCustomComponents = {};

  @override
  void dispose() {
    _pageController.dispose();
    _semNameController.dispose();
    _collegeController.dispose();
    _branchController.dispose();
    _subNameController.dispose();
    _subCodeController.dispose();
    _subCreditsController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 2) {
      // Validation for Step 1
      if (_currentStep == 0 && _semNameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a Semester Name')),
        );
        return;
      }
      // Validation for Step 2
      if (_currentStep == 1 && _subjects.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add at least one subject')),
        );
        return;
      }

      // Populate default templates for subjects on moving to Step 3
      if (_currentStep == 1) {
        for (final s in _subjects) {
          if (!_subjectTemplates.containsKey(s.code)) {
            _subjectTemplates[s.code] = 'integrated'; // Default preset
          }
        }
      }

      setState(() {
        _currentStep++;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _finishWizard();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pop(context);
    }
  }

  // --- Component Presets Generators ---
  List<GenericComponent> _getComponentsForTemplate(String code, String templateType) {
    if (templateType == 'custom') {
      return _subjectCustomComponents[code] ?? [];
    }

    if (templateType == 'integrated') {
      return [
        GenericComponent(
          id: 'cie_group',
          name: 'CIE',
          type: 'grouped',
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
    } else if (templateType == 'theoryA') {
      return [
        GenericComponent(
          id: 'cie_group',
          name: 'CIE',
          type: 'grouped',
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
    } else if (templateType == 'theoryB') {
      return [
        GenericComponent(
          id: 'cie_group',
          name: 'CIE',
          type: 'grouped',
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
    } else if (templateType == 'practical') {
      return [
        GenericComponent(id: 'internal', name: 'Practical Internal', type: 'standalone', maxMarks: 50, weight: 50),
        GenericComponent(id: 'see', name: 'Semester End Exam', type: 'standalone', maxMarks: 50, weight: 50),
      ];
    } else {
      // external
      return [
        GenericComponent(id: 'assignments', name: 'Assignments', type: 'standalone', maxMarks: 25, weight: 25),
        GenericComponent(id: 'see', name: 'Final Exam', type: 'standalone', maxMarks: 75, weight: 75),
      ];
    }
  }

  double _getComponentsTotalWeight(List<GenericComponent> comps) {
    return comps.fold(0.0, (sum, c) => sum + c.weight);
  }

  bool _isSubjectConfigValid(Subject s) {
    final type = _subjectTemplates[s.code] ?? 'integrated';
    final comps = _getComponentsForTemplate(s.code, type);
    return _getComponentsTotalWeight(comps) == 100.0;
  }

  bool _isAllSubjectsValid() {
    return _subjects.every((s) => _isSubjectConfigValid(s));
  }

  void _finishWizard() {
    if (!_isAllSubjectsValid()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please ensure all subjects have components totaling exactly 100 marks.')),
      );
      return;
    }

    // Build Grade Scheme
    GradeScheme scheme;
    if (_gradeSchemePreset == 'BMSCE') {
      scheme = GradeScheme.defaultBMSCE;
    } else if (_gradeSchemePreset == 'VTU') {
      scheme = GradeScheme.defaultVTU;
    } else {
      scheme = GradeScheme(boundaries: _customBoundaries);
    }

    // Build final subjects list with correct templates
    final finalSubjects = _subjects.map((s) {
      final template = _subjectTemplates[s.code] ?? 'integrated';
      final comps = _getComponentsForTemplate(s.code, template);
      return s.copyWith(components: comps);
    }).toList();

    final totalCredits = finalSubjects.fold(0, (sum, s) => sum + s.credits);

    final finalSemester = Semester(
      name: _semNameController.text.trim(),
      collegeName: _collegeController.text.trim(),
      branchName: _branchController.text.trim(),
      totalCredits: totalCredits,
      subjects: finalSubjects,
      gradeScheme: scheme,
    );

    context.read<AcademicProvider>().createCustomSemester(finalSemester);
    
    // Pop back to main dashboard
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return MeshGradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.close, color: AppTheme.textColorPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Semester Creator Wizard',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppTheme.textColorPrimary,
            ),
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            // Top Step Indicator
            _buildStepIndicator(),
            
            // Main Wizard Forms PageView
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep1Details(),
                  _buildStep2Subjects(),
                  _buildStep3Components(),
                ],
              ),
            ),

            // Bottom Buttons
            _buildBottomButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStepBubble(0, 'Details'),
          _buildStepLine(0),
          _buildStepBubble(1, 'Subjects'),
          _buildStepLine(1),
          _buildStepBubble(2, 'Components'),
        ],
      ),
    );
  }

  Widget _buildStepBubble(int stepIndex, String title) {
    final isActive = _currentStep == stepIndex;
    final isCompleted = _currentStep > stepIndex;
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive
                ? AppTheme.primaryBlue
                : isCompleted
                    ? AppTheme.accentGreen
                    : AppTheme.borderColor.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? Colors.white : Colors.transparent,
              width: 1.5,
            ),
          ),
          alignment: Alignment.center,
          child: isCompleted
              ? const Icon(Icons.check, color: Colors.white, size: 16)
              : Text(
                  '${stepIndex + 1}',
                  style: TextStyle(
                    color: isActive ? Colors.white : AppTheme.textColorSecondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 9,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? AppTheme.textColorPrimary : AppTheme.textColorSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(int afterStep) {
    final isPassed = _currentStep > afterStep;
    return Expanded(
      child: Container(
        height: 2,
        color: isPassed ? AppTheme.accentGreen : AppTheme.borderColor.withOpacity(0.3),
        margin: const EdgeInsets.only(bottom: 12),
      ),
    );
  }

  // --- STEP 1: SEMESTER DETAILS ---
  Widget _buildStep1Details() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Semester Information',
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textColorPrimary, fontSize: 13),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _semNameController,
                  style: TextStyle(color: AppTheme.textColorPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Semester Name',
                    hintText: 'e.g. BMSCE CSE Semester 4',
                    border: const OutlineInputBorder(),
                    labelStyle: TextStyle(color: AppTheme.textColorSecondary),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _collegeController,
                  style: TextStyle(color: AppTheme.textColorPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'College Name (Optional)',
                    border: const OutlineInputBorder(),
                    labelStyle: TextStyle(color: AppTheme.textColorSecondary),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _branchController,
                  style: TextStyle(color: AppTheme.textColorPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Branch Name (Optional)',
                    border: const OutlineInputBorder(),
                    labelStyle: TextStyle(color: AppTheme.textColorSecondary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Grading System Scheme',
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textColorPrimary, fontSize: 13),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: _gradeSchemePreset,
                  dropdownColor: AppTheme.cardColor,
                  style: TextStyle(color: AppTheme.textColorPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Preset Boundaries Scheme',
                    border: const OutlineInputBorder(),
                    labelStyle: TextStyle(color: AppTheme.textColorSecondary),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'BMSCE', child: Text('BMSCE Standard (e.g. S: 90+, A: 80+)')),
                    DropdownMenuItem(value: 'VTU', child: Text('VTU Standard (e.g. O: 90+, A+: 80+)')),
                    DropdownMenuItem(value: 'Custom', child: Text('Custom Scheme Editor...')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _gradeSchemePreset = val;
                      });
                    }
                  },
                ),
                if (_gradeSchemePreset == 'Custom') ...[
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'GRADE BOUNDARIES EDITOR',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.textColorSecondary),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _customBoundaries.insert(
                              0,
                              const GradeBoundary(minMarks: 90.0, maxMarks: 100.0, gradeLetter: 'NEW', gradePoints: 10),
                            );
                          });
                        },
                        icon: const Icon(Icons.add, size: 12),
                        label: const Text('Add Boundary', style: TextStyle(fontSize: 10)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...List.generate(_customBoundaries.length, (idx) {
                    final b = _customBoundaries[idx];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              initialValue: b.gradeLetter,
                              style: TextStyle(color: AppTheme.textColorPrimary, fontSize: 11),
                              decoration: const InputDecoration(labelText: 'Grade', border: OutlineInputBorder(), contentPadding: EdgeInsets.all(4)),
                              onChanged: (val) {
                                _customBoundaries[idx] = GradeBoundary(minMarks: b.minMarks, maxMarks: b.maxMarks, gradeLetter: val, gradePoints: b.gradePoints);
                              },
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              initialValue: b.gradePoints.toString(),
                              keyboardType: TextInputType.number,
                              style: TextStyle(color: AppTheme.textColorPrimary, fontSize: 11),
                              decoration: const InputDecoration(labelText: 'Points', border: OutlineInputBorder(), contentPadding: EdgeInsets.all(4)),
                              onChanged: (val) {
                                final pts = int.tryParse(val) ?? 0;
                                _customBoundaries[idx] = GradeBoundary(minMarks: b.minMarks, maxMarks: b.maxMarks, gradeLetter: b.gradeLetter, gradePoints: pts);
                              },
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              initialValue: b.minMarks.toStringAsFixed(0),
                              keyboardType: TextInputType.number,
                              style: TextStyle(color: AppTheme.textColorPrimary, fontSize: 11),
                              decoration: const InputDecoration(labelText: 'Min Marks', border: OutlineInputBorder(), contentPadding: EdgeInsets.all(4)),
                              onChanged: (val) {
                                final minVal = double.tryParse(val) ?? 0.0;
                                _customBoundaries[idx] = GradeBoundary(minMarks: minVal, maxMarks: b.maxMarks, gradeLetter: b.gradeLetter, gradePoints: b.gradePoints);
                              },
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete_outline, color: AppTheme.accentRed.withOpacity(0.8), size: 16),
                            onPressed: () {
                              setState(() {
                                _customBoundaries.removeAt(idx);
                              });
                            },
                          ),
                        ],
                      ),
                    );
                  }),
                ],
                const SizedBox(height: 12),
                _buildLivePreviewTable(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- STEP 2: ADD SUBJECTS ---
  Widget _buildStep2Subjects() {
    final int totalCredits = _subjects.fold(0, (sum, s) => sum + s.credits);
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Add Subject Form Card
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add Course / Subject',
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textColorPrimary, fontSize: 13),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _subCodeController,
                        style: TextStyle(color: AppTheme.textColorPrimary, fontSize: 13),
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          labelText: 'Code',
                          hintText: 'ADA',
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          labelStyle: TextStyle(color: AppTheme.textColorSecondary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _subNameController,
                        style: TextStyle(color: AppTheme.textColorPrimary, fontSize: 13),
                        decoration: InputDecoration(
                          labelText: 'Course Name',
                          hintText: 'Algorithms',
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          labelStyle: TextStyle(color: AppTheme.textColorSecondary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _subCreditsController,
                        style: TextStyle(color: AppTheme.textColorPrimary, fontSize: 13),
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Credits',
                          hintText: '4',
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          labelStyle: TextStyle(color: AppTheme.textColorSecondary),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    final code = _subCodeController.text.trim().toUpperCase();
                    final name = _subNameController.text.trim();
                    final credits = int.tryParse(_subCreditsController.text) ?? 4;
                    if (code.isEmpty || name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please fill Code and Name')),
                      );
                      return;
                    }

                    if (_subjects.any((s) => s.code == code)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Subject code already added')),
                      );
                      return;
                    }

                    setState(() {
                      _subjects.add(Subject(code: code, name: name, credits: credits, components: const []));
                      _subCodeController.clear();
                      _subNameController.clear();
                      _subCreditsController.text = '4';
                    });
                  },
                  icon: const Icon(Icons.add, size: 14),
                  label: const Text('Add Course'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 36),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Live Credit Indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Semester Credits',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                ),
                Text(
                  '$totalCredits Credits',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppTheme.primaryBlue),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // List of Added Subjects
          _subjects.isEmpty
              ? Container(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text(
                      'No subjects added yet. Add courses above.',
                      style: TextStyle(color: AppTheme.textColorSecondary, fontSize: 11),
                    ),
                  ),
                )
              : Column(
                  children: List.generate(_subjects.length, (idx) {
                    final s = _subjects[idx];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8.0),
                      child: GlassCard(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppTheme.subjectBgColor(s.code, s.name),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                s.code.substring(0, s.code.length.clamp(0, 3)),
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.subjectTextColor(s.code, s.name),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s.name,
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textColorPrimary),
                                  ),
                                  Text(
                                    'Code: ${s.code} | Credits: ${s.credits}',
                                    style: TextStyle(fontSize: 9, color: AppTheme.textColorSecondary),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete_outline, color: AppTheme.accentRed.withOpacity(0.8), size: 18),
                              onPressed: () {
                                setState(() {
                                  _subjects.removeAt(idx);
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
        ],
      ),
    );
  }

  // --- STEP 3: COMPONENT SETUP ---
  Widget _buildStep3Components() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Select Subject Templates',
            style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textColorPrimary, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            'Each subject must configure components totaling 100 marks.',
            style: TextStyle(color: AppTheme.textColorSecondary, fontSize: 10),
          ),
          const SizedBox(height: 14),

          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: _subjects.length,
              itemBuilder: (context, idx) {
                final s = _subjects[idx];
                final currentTemplate = _subjectTemplates[s.code] ?? 'integrated';
                final components = _getComponentsForTemplate(s.code, currentTemplate);
                final totalWeight = _getComponentsTotalWeight(components);
                final isValid = totalWeight == 100.0;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12.0),
                  child: GlassCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${s.code}: ${s.name}',
                              style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textColorPrimary, fontSize: 12),
                            ),
                            Icon(
                              isValid ? Icons.check_circle_outline : Icons.error_outline_rounded,
                              color: isValid ? AppTheme.accentGreen : AppTheme.accentRed,
                              size: 16,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          value: currentTemplate,
                          dropdownColor: AppTheme.cardColor,
                          style: TextStyle(color: AppTheme.textColorPrimary, fontSize: 11),
                          decoration: const InputDecoration(
                            labelText: 'Course Component Template',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'integrated', child: Text('Integrated (CIE 20 + AAT 5 + Lab 25 + SEE 50)')),
                            DropdownMenuItem(value: 'theoryA', child: Text('Theory (CIE 40 + AAT 5 + Quiz 5 + SEE 50)')),
                            DropdownMenuItem(value: 'theoryB', child: Text('Theory (CIE 40 + AAT 10 + SEE 50)')),
                            DropdownMenuItem(value: 'practical', child: Text('Practical (Internals 50 + SEE 50)')),
                            DropdownMenuItem(value: 'external', child: Text('External/NPTEL (Assignments 25 + Exam 75)')),
                            DropdownMenuItem(value: 'custom', child: Text('Custom Component Layout...')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _subjectTemplates[s.code] = val;
                                if (val == 'custom' && !_subjectCustomComponents.containsKey(s.code)) {
                                  _subjectCustomComponents[s.code] = [];
                                }
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Configured Marks: ${totalWeight.toStringAsFixed(0)} / 100',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: isValid ? AppTheme.textColorSecondary : AppTheme.accentRed,
                              ),
                            ),
                            if (currentTemplate == 'custom')
                              TextButton(
                                onPressed: () => _openCustomComponentMixEditor(s.code),
                                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                                child: const Text('Configure Custom Mix', style: TextStyle(fontSize: 10)),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _openCustomComponentMixEditor(String code) {
    final list = _subjectCustomComponents[code] ?? [];
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final double currentSum = _getComponentsTotalWeight(list);
            return Dialog(
              backgroundColor: AppTheme.cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 450),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Configure Custom Mix ($code)',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textColorPrimary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Total weight must equal 100. Current: ${currentSum.toStringAsFixed(0)}',
                      style: TextStyle(fontSize: 10, color: currentSum == 100 ? AppTheme.accentGreen : AppTheme.accentRed),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: list.isEmpty
                          ? Center(child: Text('No custom components added.', style: TextStyle(color: AppTheme.textColorSecondary, fontSize: 11)))
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: list.length,
                              itemBuilder: (context, index) {
                                final c = list[index];
                                return Padding(
                                  key: ValueKey(c.id),
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: TextFormField(
                                          initialValue: c.name,
                                          style: TextStyle(color: AppTheme.textColorPrimary, fontSize: 11),
                                          decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder(), contentPadding: EdgeInsets.all(4)),
                                          onChanged: (val) {
                                            list[index] = c.copyWith(name: val);
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: TextFormField(
                                          initialValue: c.maxMarks.toStringAsFixed(0),
                                          keyboardType: TextInputType.number,
                                          style: TextStyle(color: AppTheme.textColorPrimary, fontSize: 11),
                                          decoration: const InputDecoration(labelText: 'Max', border: OutlineInputBorder(), contentPadding: EdgeInsets.all(4)),
                                          onChanged: (val) {
                                            final parsed = double.tryParse(val) ?? 10;
                                            list[index] = c.copyWith(maxMarks: parsed);
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: TextFormField(
                                          initialValue: c.weight.toStringAsFixed(0),
                                          keyboardType: TextInputType.number,
                                          style: TextStyle(color: AppTheme.textColorPrimary, fontSize: 11),
                                          decoration: const InputDecoration(labelText: 'Weight', border: OutlineInputBorder(), contentPadding: EdgeInsets.all(4)),
                                          onChanged: (val) {
                                            final parsed = double.tryParse(val) ?? 10;
                                            list[index] = c.copyWith(weight: parsed);
                                            setDialogState(() {});
                                          },
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.delete_outline, color: AppTheme.accentRed.withOpacity(0.8), size: 16),
                                        onPressed: () {
                                          setDialogState(() {
                                            list.removeAt(index);
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            setDialogState(() {
                              list.add(
                                GenericComponent(
                                  id: 'custom_${DateTime.now().millisecondsSinceEpoch}_${list.length}',
                                  name: 'Component ${list.length + 1}',
                                  type: 'standalone',
                                  maxMarks: 10,
                                  weight: 10,
                                ),
                              );
                            });
                          },
                          icon: const Icon(Icons.add, size: 14),
                          label: const Text('Add Component', style: TextStyle(fontSize: 11)),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _subjectCustomComponents[code] = list;
                            });
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue, foregroundColor: Colors.white),
                          child: const Text('Done'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  List<GradeBoundary> get _currentPreviewBoundaries {
    if (_gradeSchemePreset == 'BMSCE') {
      return GradeScheme.defaultBMSCE.boundaries;
    } else if (_gradeSchemePreset == 'VTU') {
      return GradeScheme.defaultVTU.boundaries;
    } else {
      return _customBoundaries;
    }
  }

  Widget _buildLivePreviewTable() {
    final boundaries = _currentPreviewBoundaries;
    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.08),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Expanded(flex: 2, child: Text('Grade', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textColorPrimary))),
                Expanded(flex: 3, child: Text('Marks Range', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textColorPrimary))),
                Expanded(flex: 2, child: Text('Grade Points', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textColorPrimary), textAlign: TextAlign.right)),
              ],
            ),
          ),
          ...List.generate(boundaries.length, (i) {
            final b = boundaries[i];
            final isLast = i == boundaries.length - 1;
            final nextMin = i > 0 ? boundaries[i - 1].minMarks : 100.0;
            final rangeText = isLast
                ? '0 – ${(b.maxMarks).toStringAsFixed(0)}'
                : '${b.minMarks.toStringAsFixed(0)} – ${(nextMin - 1).toStringAsFixed(0)}';
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppTheme.borderColor.withOpacity(0.25)),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _gradeColor(b.gradePoints).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        b.gradeLetter,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _gradeColor(b.gradePoints),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: Text(
                      rangeText,
                      style: TextStyle(fontSize: 11, color: AppTheme.textColorSecondary),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '${b.gradePoints} / 10',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _gradeColor(b.gradePoints),
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Color _gradeColor(int gradePoints) {
    if (gradePoints >= 9) return const Color(0xFF22C55E);
    if (gradePoints >= 7) return const Color(0xFF3B82F6);
    if (gradePoints >= 5) return const Color(0xFFF59E0B);
    if (gradePoints >= 4) return const Color(0xFFF97316);
    return const Color(0xFFEF4444);
  }

  Widget _buildBottomButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton(
            onPressed: _prevStep,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.borderColor.withOpacity(0.2),
              foregroundColor: AppTheme.textColorPrimary,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(_currentStep == 0 ? 'Exit' : 'Back'),
          ),
          ElevatedButton(
            onPressed: _nextStep,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(_currentStep == 2 ? 'Finish & Launch' : 'Next'),
          ),
        ],
      ),
    );
  }
}
