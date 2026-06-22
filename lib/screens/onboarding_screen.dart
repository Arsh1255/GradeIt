import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../services/academic_provider.dart';
import '../widgets/glass_card.dart';
import '../widgets/mesh_gradient_background.dart';
import 'semester_wizard_screen.dart';
import '../widgets/academic_data_helper.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MeshGradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(flex: 1),
                
                // Logo & Header
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withOpacity(0.12),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.3), width: 1.5),
                    ),
                    child: Icon(
                      Icons.auto_graph_rounded,
                      size: 44,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'GradeIt',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textColorPrimary,
                    letterSpacing: -1.0,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Simulate & Optimize Your Academic Planning',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textColorSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const Spacer(flex: 2),

                // Option 1: Default Template Card
                GestureDetector(
                  onTap: () {
                    context.read<AcademicProvider>().useDefaultTemplate();
                  },
                  child: GlassCard(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.school_rounded, color: AppTheme.primaryBlue, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'BMSCE CSE Semester 4',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textColorPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Continue with the default BMSCE 8-subject template. Ready to go.',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppTheme.textColorSecondary,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.textColorSecondary, size: 16),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Option 2: Build My Semester Card
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SemesterWizardScreen()),
                    );
                  },
                  child: GlassCard(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.accentGreen.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.architecture_rounded, color: AppTheme.accentGreen, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Build My Semester',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textColorPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Wizard-guided custom layout for any college, credits, or grading bounds.',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppTheme.textColorSecondary,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.textColorSecondary, size: 16),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Option 3: Import Classmate Structure Card
                GestureDetector(
                  onTap: () {
                    AcademicDataHelper.showImportDialog(context, context.read<AcademicProvider>());
                  },
                  child: GlassCard(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.file_upload_outlined, color: AppTheme.primaryBlue, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Import Classmate Structure',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textColorPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Import a course setup shared as a .gradeit file by your classmate.',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppTheme.textColorSecondary,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.textColorSecondary, size: 16),
                      ],
                    ),
                  ),
                ),
                
                const Spacer(flex: 2),
                
                Text(
                  'GradeIt uses completely local offline storage.',
                  style: TextStyle(
                    fontSize: 9,
                    color: AppTheme.textColorSecondary.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
