import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme.dart';
import '../models/subject.dart';
import '../models/semester.dart';
import '../models/generic_component.dart';
import '../models/grade_scheme.dart';
import '../services/academic_provider.dart';
import '../widgets/glass_card.dart';
import '../widgets/glass_dial.dart';
import '../widgets/mesh_gradient_background.dart';
import 'subject_detail_screen.dart';
import 'profile_screen.dart';
import '../widgets/academic_data_helper.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AcademicProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const MeshGradientBackground(
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
              ),
            ),
          );
        }

        return MeshGradientBackground(
          bottomNavigationBar: provider.isConfigMode ? _buildConfigBottomBar(context, provider) : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              // ── TOP HEADER ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(22.0, 36.0, 16.0, 12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Title + subtitle
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 280),
                            child: Text(
                              provider.isConfigMode ? 'Design Workspace' : 'GradeIt',
                              key: ValueKey(provider.isConfigMode),
                              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: provider.isConfigMode
                                    ? AppTheme.accentTeal
                                    : AppTheme.textColorPrimary,
                                fontSize: 28,
                                letterSpacing: -0.8,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            provider.isConfigMode
                                ? 'Structural edits only — save when done'
                                : '${provider.userProfile.name} • ${provider.semester?.name ?? "Semester"}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: provider.isConfigMode
                                  ? AppTheme.accentTeal.withOpacity(0.75)
                                  : AppTheme.textColorSecondary,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Right-side buttons — hidden in config mode
                    if (!provider.isConfigMode)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _topIconBtn(
                            icon: provider.isDarkMode
                                ? Icons.light_mode_rounded
                                : Icons.dark_mode_rounded,
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              provider.toggleDarkMode();
                            },
                            tooltip: 'Toggle theme',
                          ),
                          const SizedBox(width: 6),
                          _topIconBtn(
                            icon: Icons.settings_rounded,
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const ProfileScreen()),
                            ),
                            tooltip: 'Settings',
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              // ── ANALYTICS CARDS (tracking) / WORKSPACE NOTICE (config) ──
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 320),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.06),
                      end: Offset.zero,
                    ).animate(anim),
                    child: child,
                  ),
                ),
                child: provider.isConfigMode
                    ? _buildConfigWorkspaceBanner(context)
                    : _buildAnalyticsSection(context, provider),
              ),

              // --- SCROLLABLE COURSE LIST ---

              
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 12.0, bottom: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Course Targets',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 17,
                                        color: AppTheme.textColorPrimary,
                                      ),
                                ),
                                if (provider.isConfigMode) ...[
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.edit_note_rounded, size: 20),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    color: AppTheme.primaryBlue,
                                    onPressed: () => _showMetadataEditDialog(context, provider),
                                    tooltip: 'Edit Metadata & Grade Scheme',
                                  ),
                                ],
                              ],
                            ),
                            Text(
                              '${provider.sem4TotalCredits} Credits Total',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textColorSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Subject Cards
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ...provider.subjects.map((sub) => _buildSubjectCard(context, sub, provider)).toList(),
                            
                            if (provider.isConfigMode) ...[
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: () => _showEditSubjectDialog(context, provider, null),
                                icon: const Icon(Icons.add_rounded, size: 16),
                                label: const Text('Add Subject'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryBlue.withOpacity(0.08),
                                  foregroundColor: AppTheme.primaryBlue,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: BorderSide(color: AppTheme.primaryBlue.withOpacity(0.2)),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),
                      if (!provider.isConfigMode)
                        Center(
                          child: TextButton.icon(
                            onPressed: () => _confirmEnterConfigMode(context, provider),
                            icon: Icon(Icons.edit_road_rounded, size: 16, color: AppTheme.textColorSecondary),
                            label: Text(
                              'Modify Semester Structure',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textColorSecondary,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: AppTheme.borderColor.withOpacity(0.5)),
                              ),
                            ),
                          ),
                        ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSubjectCard(BuildContext context, Subject subject, AcademicProvider provider) {
    final bgTint = AppTheme.subjectBgColor(subject.code, subject.name);
    final textTint = AppTheme.subjectTextColor(subject.code, subject.name);
    final icon = AppTheme.subjectIcon(subject.code, subject.name);

    final idx = provider.subjects.indexOf(subject);
    final total = provider.subjects.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: GlassCard(
        padding: EdgeInsets.zero,
        borderRadius: 20,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SubjectDetailScreen(subjectCode: subject.code),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              // ── ROW 1: Icon + Subject Info + (Tracking) Score Badge ──
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Subject icon
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: bgTint,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: textTint, size: 22),
                  ),
                  const SizedBox(width: 14),

                  // Name + code/credits
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subject.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textColorPrimary,
                            height: 1.25,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${subject.code} • ${subject.credits} Credits',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textColorSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Tracking mode: predicted score badge on the right
                  if (!provider.isConfigMode) ...[
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${subject.predictedScore.toStringAsFixed(0)}/100',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textColorPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: bgTint,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Grade ${subject.getPredictedGradeLetter(provider.gradeScheme)}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: textTint,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),

              // ── ROW 2 (Config mode only): editing controls ──
              if (provider.isConfigMode) ...[
                const SizedBox(height: 12),
                Container(
                  height: 1,
                  color: AppTheme.borderColor.withOpacity(0.25),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Reorder up
                    _configIconBtn(
                      icon: Icons.arrow_upward_rounded,
                      color: idx > 0
                          ? AppTheme.textColorSecondary
                          : AppTheme.textColorSecondary.withOpacity(0.2),
                      onPressed: idx > 0
                          ? () => provider.reorderSubjects(idx, idx - 1)
                          : null,
                      tooltip: 'Move up',
                    ),
                    const SizedBox(width: 4),
                    // Reorder down
                    _configIconBtn(
                      icon: Icons.arrow_downward_rounded,
                      color: idx < total - 1
                          ? AppTheme.textColorSecondary
                          : AppTheme.textColorSecondary.withOpacity(0.2),
                      onPressed: idx < total - 1
                          ? () => provider.reorderSubjects(idx, idx + 2)
                          : null,
                      tooltip: 'Move down',
                    ),
                    const Spacer(),
                    // Edit
                    _configIconBtn(
                      icon: Icons.edit_outlined,
                      color: AppTheme.primaryBlue,
                      onPressed: () => _showEditSubjectDialog(context, provider, subject),
                      tooltip: 'Edit subject',
                      bgColor: AppTheme.primaryBlue.withOpacity(0.08),
                    ),
                    const SizedBox(width: 8),
                    // Delete
                    _configIconBtn(
                      icon: Icons.delete_outline_rounded,
                      color: AppTheme.accentRed,
                      onPressed: () => _confirmDeleteSubject(context, provider, subject),
                      tooltip: 'Delete subject',
                      bgColor: AppTheme.accentRed.withOpacity(0.08),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Small tappable icon button used in config mode controls row
  Widget _configIconBtn({
    required IconData icon,
    required Color color,
    required VoidCallback? onPressed,
    String? tooltip,
    Color? bgColor,
  }) {
    return Tooltip(
      message: tooltip ?? '',
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: bgColor ?? Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }



  // --- ONE UI EXPORT BOTTOM SHEET MODAL ---
  
  // ─── Header icon button helper ───────────────────────────────────────────
  Widget _topIconBtn({
    required IconData icon,
    required VoidCallback onPressed,
    String? tooltip,
  }) {
    return Tooltip(
      message: tooltip ?? '',
      child: Material(
        color: AppTheme.primaryBlue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          splashColor: AppTheme.primaryBlue.withOpacity(0.12),
          highlightColor: AppTheme.primaryBlue.withOpacity(0.06),
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Icon(icon, size: 20, color: AppTheme.primaryBlue),
          ),
        ),
      ),
    );
  }

  // ─── Config Workspace Banner ─────────────────────────────────────────────
  Widget _buildConfigWorkspaceBanner(BuildContext context) {
    return Padding(
      key: const ValueKey('config_banner'),
      padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 8.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.accentTeal.withOpacity(0.07),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.accentTeal.withOpacity(0.22), width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.accentTeal.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.architecture_rounded, color: AppTheme.accentTeal, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Configuration Mode Active',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.accentTeal,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Add, remove or reorder subjects and components. Stats are hidden until you save.',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.accentTeal.withOpacity(0.7),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Analytics section (tracking mode only) ──────────────────────────────
  Widget _buildAnalyticsSection(BuildContext context, AcademicProvider provider) {
    return Column(
      key: const ValueKey('analytics'),
      children: [
        // GPA Dials
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 6.0),
          child: GlassCard(
            padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
            borderRadius: 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: GlassDial(
                    value: provider.predictedSgpa,
                    maxValue: provider.maxSgpa,
                    label: 'Predicted SGPA',
                    activeColor: AppTheme.primaryBlue,
                  ),
                ),
                Container(width: 1.0, height: 70, color: AppTheme.borderColor),
                Expanded(
                  child: GlassDial(
                    value: provider.predictedCgpa,
                    maxValue: provider.maxCgpa,
                    label: 'Predicted CGPA',
                    activeColor: AppTheme.accentTeal,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Metrics Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 8.0),
          child: Row(
            children: [
              // Completion
              Expanded(
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 14.0),
                  borderRadius: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Completion',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: AppTheme.textColorSecondary)),
                      const SizedBox(height: 4),
                      Text(
                        '${provider.semesterCompletionPercentage.toStringAsFixed(0)}%',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textColorPrimary),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: provider.semesterCompletionPercentage / 100,
                          minHeight: 5,
                          backgroundColor: AppTheme.borderColor.withOpacity(0.4),
                          valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Lost Marks
              Expanded(
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 14.0),
                  borderRadius: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Lost Marks',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: AppTheme.textColorSecondary)),
                      const SizedBox(height: 4),
                      Text(
                        provider.totalMarksLost.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: provider.totalMarksLost > 15 ? AppTheme.accentRed : AppTheme.textColorPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Out of 800 total',
                          style: TextStyle(fontSize: 9, color: AppTheme.textColorSecondary.withOpacity(0.8), fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Achievable
              Expanded(
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 14.0),
                  borderRadius: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Achievable',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: AppTheme.textColorSecondary)),
                      const SizedBox(height: 4),
                      Text(
                        provider.totalRemainingAchievable.toStringAsFixed(1),
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textColorPrimary),
                      ),
                      const SizedBox(height: 8),
                      Text('Pending marks',
                          style: TextStyle(fontSize: 9, color: AppTheme.textColorSecondary.withOpacity(0.8), fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- CONFIGURATION MODE HELPERS & WORKSPACES ---

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
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
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
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppTheme.cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Discard Changes?',
            style: TextStyle(color: AppTheme.textColorPrimary, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to discard all structural changes? This cannot be undone.',
            style: TextStyle(color: AppTheme.textColorSecondary, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Keep Editing'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                provider.cancelConfigurationMode();
              },
              child: const Text('Discard', style: TextStyle(color: AppTheme.accentRed)),
            ),
          ],
        );
      },
    );
  }

  void _saveDraftConfig(BuildContext context, AcademicProvider provider) {
    final errors = provider.saveConfigurationMode();
    if (errors.isNotEmpty) {
      AcademicDataHelper.showValidationAlert(context, errors);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Semester configuration saved and locked!'),
          backgroundColor: AppTheme.accentTeal,
        ),
      );
      // Show one-time CGPA setup alert
      SharedPreferences.getInstance().then((prefs) {
        if (prefs.getBool('has_shown_cgpa_alert') != true) {
          prefs.setBool('has_shown_cgpa_alert', true);
          if (context.mounted) {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: AppTheme.cardColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: Text('Calculate Effective CGPA?',
                    style: TextStyle(color: AppTheme.textColorPrimary, fontWeight: FontWeight.bold)),
                content: Text(
                  'Head to the Profile screen to set your previous semester SGPA and credits. This allows GradeIt to calculate your accurate cumulative CGPA!',
                  style: TextStyle(color: AppTheme.textColorSecondary, fontSize: 13),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Got it!',
                        style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          }
        }
      });
    }
  }

  void _showEditSubjectDialog(BuildContext context, AcademicProvider provider, Subject? subject) {
    final codeController = TextEditingController(text: subject?.code ?? '');
    final nameController = TextEditingController(text: subject?.name ?? '');
    final creditsController = TextEditingController(text: subject?.credits.toString() ?? '4');
    
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppTheme.cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            subject == null ? 'Add Subject' : 'Edit Subject',
            style: TextStyle(color: AppTheme.textColorPrimary, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: codeController,
                  decoration: const InputDecoration(
                    labelText: 'Subject Code (e.g. MAT41)',
                    labelStyle: TextStyle(fontSize: 12),
                  ),
                  style: TextStyle(color: AppTheme.textColorPrimary),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Subject Name (e.g. Mathematics IV)',
                    labelStyle: TextStyle(fontSize: 12),
                  ),
                  style: TextStyle(color: AppTheme.textColorPrimary),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: creditsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Credits (e.g. 4)',
                    labelStyle: TextStyle(fontSize: 12),
                  ),
                  style: TextStyle(color: AppTheme.textColorPrimary),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final code = codeController.text.trim();
                final name = nameController.text.trim();
                final credits = int.tryParse(creditsController.text.trim()) ?? 0;
                
                if (code.isEmpty || name.isEmpty || credits <= 0) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('Please enter valid details.')),
                  );
                  return;
                }
                
                if (subject == null) {
                  final defaultComp = GenericComponent(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: 'Theory Marks',
                    type: 'standalone',
                    maxMarks: 100,
                    weight: 100,
                    scoredMarks: null,
                    predictedMarks: 0,
                    isCompleted: false,
                  );
                  provider.addSubject(Subject(
                    code: code,
                    name: name,
                    credits: credits,
                    components: [defaultComp],
                  ));
                } else {
                  provider.updateSubject(
                    subject.code,
                    subject.copyWith(code: code, name: name, credits: credits),
                  );
                }
                Navigator.pop(dialogContext);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue, foregroundColor: Colors.white),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteSubject(BuildContext context, AcademicProvider provider, Subject subject) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppTheme.cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Delete Subject?',
            style: TextStyle(color: AppTheme.textColorPrimary, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to delete ${subject.name} (${subject.code})? All associated marks and components will be permanently deleted.',
            style: TextStyle(color: AppTheme.textColorSecondary, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                provider.deleteSubject(subject.code);
                Navigator.pop(dialogContext);
              },
              child: const Text('Delete', style: TextStyle(color: AppTheme.accentRed)),
            ),
          ],
        );
      },
    );
  }

  void _showMetadataEditDialog(BuildContext context, AcademicProvider provider) {
    final sem = provider.semester;
    if (sem == null) return;

    final nameController = TextEditingController(text: sem.name);
    final collegeController = TextEditingController(text: sem.collegeName ?? '');
    final branchController = TextEditingController(text: sem.branchName ?? '');
    final creditsController = TextEditingController(text: sem.totalCredits.toString());

    // Detect starting preset
    String _selectedPreset = _detectPreset(sem.gradeScheme);
    List<GradeBoundary> _boundaries = List<GradeBoundary>.from(sem.gradeScheme.boundaries);
    
    // Persist controllers to avoid focus loss during typing rebuilds
    final controllers = _boundaries.map((b) => TextEditingController(text: b.minMarks.toStringAsFixed(0))).toList();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {

            void _applyPreset(String preset) {
              setState(() {
                _selectedPreset = preset;
                if (preset == 'BMSCE') {
                  _boundaries = List<GradeBoundary>.from(GradeScheme.defaultBMSCE.boundaries);
                } else if (preset == 'VTU') {
                  _boundaries = List<GradeBoundary>.from(GradeScheme.defaultVTU.boundaries);
                }
                // Update controller texts to match
                for (int i = 0; i < _boundaries.length && i < controllers.length; i++) {
                  controllers[i].text = _boundaries[i].minMarks.toStringAsFixed(0);
                }
              });
            }

            return AlertDialog(
              backgroundColor: AppTheme.cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(
                'Edit Semester Metadata & Grades',
                style: TextStyle(color: AppTheme.textColorPrimary, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              content: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(dialogContext).size.height * 0.65,
                  maxWidth: MediaQuery.of(dialogContext).size.width,
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // --- METADATA FIELDS ---
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Semester Name (e.g. 4th Sem CSE)'),
                        style: TextStyle(color: AppTheme.textColorPrimary),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: collegeController,
                        decoration: const InputDecoration(labelText: 'College Name (optional)'),
                        style: TextStyle(color: AppTheme.textColorPrimary),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: branchController,
                        decoration: const InputDecoration(labelText: 'Branch Name (optional)'),
                        style: TextStyle(color: AppTheme.textColorPrimary),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: creditsController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Total Semester Credits target'),
                        style: TextStyle(color: AppTheme.textColorPrimary),
                      ),

                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 8),

                      // --- GRADE SCHEME SECTION ---
                      Text(
                        'Grade Scheme',
                        style: TextStyle(color: AppTheme.textColorPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),

                      // Preset chips
                      Row(
                        children: ['BMSCE', 'VTU', 'Custom'].map((preset) {
                          final isSelected = _selectedPreset == preset;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: GestureDetector(
                              onTap: () => _applyPreset(preset),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppTheme.primaryBlue : AppTheme.primaryBlue.withOpacity(0.07),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected ? AppTheme.primaryBlue : AppTheme.borderColor,
                                    width: 1.2,
                                  ),
                                ),
                                child: Text(
                                  preset,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.white : AppTheme.textColorSecondary,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 16),

                      // Custom min-marks editors (only shown in Custom mode)
                      if (_selectedPreset == 'Custom') ...[
                        Text(
                          'Edit minimum marks per grade:',
                          style: TextStyle(color: AppTheme.textColorSecondary, fontSize: 11),
                        ),
                        const SizedBox(height: 8),
                        ..._boundaries.asMap().entries.map((entry) {
                          final index = entry.key;
                          final boundary = entry.value;
                          final ctrl = controllers[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3.0),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 80,
                                  child: Text(
                                    'Grade ${boundary.gradeLetter}',
                                    style: TextStyle(color: AppTheme.textColorPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                ),
                                Text('≥ ', style: TextStyle(color: AppTheme.textColorSecondary, fontSize: 12)),
                                SizedBox(
                                  width: 60,
                                  child: TextField(
                                    controller: ctrl,
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: AppTheme.textColorPrimary, fontSize: 12),
                                    decoration: InputDecoration(
                                      isDense: true,
                                      contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    onChanged: (val) {
                                      final marks = double.tryParse(val) ?? 0.0;
                                      setState(() {
                                        _boundaries[index] = GradeBoundary(
                                          gradeLetter: boundary.gradeLetter,
                                          minMarks: marks,
                                          maxMarks: boundary.maxMarks,
                                          gradePoints: boundary.gradePoints,
                                        );
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'GP ${boundary.gradePoints}',
                                  style: TextStyle(color: AppTheme.textColorSecondary, fontSize: 11),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        const SizedBox(height: 12),
                      ],

                      // --- LIVE PREVIEW TABLE ---
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.borderColor.withOpacity(0.4)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Table header
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
                            // Table rows
                            ...List.generate(_boundaries.length, (i) {
                              final b = _boundaries[i];
                              final isLast = i == _boundaries.length - 1;
                              final nextMin = i > 0 ? _boundaries[i - 1].minMarks : 100.0;
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
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    final college = collegeController.text.trim();
                    final branch = branchController.text.trim();
                    final credits = int.tryParse(creditsController.text.trim()) ?? 0;

                    if (name.isEmpty || credits <= 0) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(content: Text('Please enter valid metadata details.')),
                      );
                      return;
                    }

                    provider.updateDraftSemesterMetadata(
                      name: name,
                      college: college.isEmpty ? null : college,
                      branch: branch.isEmpty ? null : branch,
                      totalCredits: credits,
                    );
                    provider.updateGradeScheme(GradeScheme(boundaries: _boundaries));
                    Navigator.pop(dialogContext);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue, foregroundColor: Colors.white),
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Returns a colour representing grade quality (green → red)
  Color _gradeColor(int gradePoints) {
    if (gradePoints >= 9) return const Color(0xFF22C55E); // green
    if (gradePoints >= 7) return const Color(0xFF3B82F6); // blue
    if (gradePoints >= 5) return const Color(0xFFF59E0B); // amber
    if (gradePoints >= 4) return const Color(0xFFF97316); // orange
    return const Color(0xFFEF4444); // red (fail)
  }

  /// Detects if the current scheme matches a known preset
  String _detectPreset(GradeScheme scheme) {
    final bmsceLetters = GradeScheme.defaultBMSCE.boundaries.map((b) => b.gradeLetter).toList();
    final vtuLetters = GradeScheme.defaultVTU.boundaries.map((b) => b.gradeLetter).toList();
    final currentLetters = scheme.boundaries.map((b) => b.gradeLetter).toList();
    if (currentLetters.join() == bmsceLetters.join()) return 'BMSCE';
    if (currentLetters.join() == vtuLetters.join()) return 'VTU';
    return 'Custom';
  }



  void _confirmEnterConfigMode(BuildContext context, AcademicProvider provider) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppTheme.cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Modify Configuration?',
            style: TextStyle(color: AppTheme.textColorPrimary, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Structural modifications can affect academic calculations and current marks mapping. Are you sure you want to enter Configuration Mode?',
            style: TextStyle(color: AppTheme.textColorSecondary, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                provider.enterConfigurationMode();
              },
              child: const Text('Confirm', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
            ),
          ],
        );
      },
    );
  }
}
