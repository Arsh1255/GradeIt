import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme.dart';
import '../models/user_profile.dart';
import '../services/academic_provider.dart';
import '../widgets/glass_card.dart';
import '../widgets/mesh_gradient_background.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _usnController;
  late TextEditingController _sem1SgpaController;
  late TextEditingController _sem1CreditsController;
  late TextEditingController _sem2SgpaController;
  late TextEditingController _sem2CreditsController;
  late TextEditingController _sem3SgpaController;
  late TextEditingController _sem3CreditsController;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<AcademicProvider>(context, listen: false);
    final profile = provider.userProfile;

    _nameController = TextEditingController(text: profile.name);
    _usnController = TextEditingController(text: profile.usn);
    _sem1SgpaController = TextEditingController(text: profile.sem1Sgpa.toString());
    _sem1CreditsController = TextEditingController(text: profile.sem1Credits.toString());
    _sem2SgpaController = TextEditingController(text: profile.sem2Sgpa.toString());
    _sem2CreditsController = TextEditingController(text: profile.sem2Credits.toString());
    _sem3SgpaController = TextEditingController(text: profile.sem3Sgpa.toString());
    _sem3CreditsController = TextEditingController(text: profile.sem3Credits.toString());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usnController.dispose();
    _sem1SgpaController.dispose();
    _sem1CreditsController.dispose();
    _sem2SgpaController.dispose();
    _sem2CreditsController.dispose();
    _sem3SgpaController.dispose();
    _sem3CreditsController.dispose();
    super.dispose();
  }

  void _saveProfile(AcademicProvider provider) {
    if (!_formKey.currentState!.validate()) return;

    final updatedProfile = UserProfile(
      name: _nameController.text.trim(),
      usn: _usnController.text.trim(),
      sem1Sgpa: double.tryParse(_sem1SgpaController.text) ?? 0.0,
      sem1Credits: int.tryParse(_sem1CreditsController.text) ?? 20,
      sem2Sgpa: double.tryParse(_sem2SgpaController.text) ?? 0.0,
      sem2Credits: int.tryParse(_sem2CreditsController.text) ?? 20,
      sem3Sgpa: double.tryParse(_sem3SgpaController.text) ?? 0.0,
      sem3Credits: int.tryParse(_sem3CreditsController.text) ?? 20,
    );

    provider.updateUserProfile(updatedProfile);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Academic profile updated successfully!',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppTheme.accentGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return MeshGradientBackground(
      child: Consumer<AcademicProvider>(
        builder: (context, provider, child) {
          final profile = provider.userProfile;

          return Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: AppTheme.textColorPrimary),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                'Configuration',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppTheme.textColorPrimary),
              ),
              centerTitle: true,
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: IconButton(
                    icon: const Icon(Icons.check, color: AppTheme.primaryBlue),
                    onPressed: () => _saveProfile(provider),
                  ),
                ),
              ],
            ),
            body: Form(
              key: _formKey,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Prior Semester Summary Card (Clean pastel Cyan background)
                    GlassCard(
                      glowColor: provider.isDarkMode ? const Color(0xFF0F2C33) : const Color(0xFFE0F7FA),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'HISTORICAL BASELINE',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textColorPrimary,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Sem 1-3 CGPA',
                                    style: TextStyle(fontSize: 11, color: AppTheme.textColorSecondary, fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    profile.priorCgpa.toStringAsFixed(2),
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textColorPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Prior Credits',
                                    style: TextStyle(fontSize: 11, color: AppTheme.textColorSecondary, fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${profile.priorTotalCredits} credits',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textColorPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Student Info Title
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                      child: Text(
                        'Student Details',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textColorPrimary),
                      ),
                    ),
                    GlassCard(
                      child: Column(
                        children: [
                          _buildTextField(
                            controller: _nameController,
                            label: 'Student Name',
                            icon: Icons.person_outline_rounded,
                            validator: (v) => v!.isEmpty ? 'Name required' : null,
                          ),
                          const SizedBox(height: 12),
                          _buildTextField(
                            controller: _usnController,
                            label: 'USN / Registration Number',
                            icon: Icons.badge_outlined,
                            validator: (v) => v!.isEmpty ? 'USN required' : null,
                          ),
                        ],
                      ),
                    ),
                     const SizedBox(height: 20),

                     // Theme Preferences
                     Text(
                       'Preferences',
                       style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textColorPrimary),
                     ),
                     const SizedBox(height: 4),
                     GlassCard(
                       child: SwitchListTile(
                         title: Text(
                           'Dark Mode',
                           style: TextStyle(
                             fontWeight: FontWeight.w700,
                             fontSize: 14,
                             color: AppTheme.textColorPrimary,
                           ),
                         ),
                         subtitle: Text(
                           'Apply deep dark theme style',
                           style: TextStyle(
                             fontSize: 11,
                             color: AppTheme.textColorSecondary,
                           ),
                         ),
                         secondary: Icon(
                           provider.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                           color: AppTheme.primaryBlue,
                         ),
                         value: provider.isDarkMode,
                         onChanged: (bool val) {
                           HapticFeedback.mediumImpact();
                           provider.toggleDarkMode();
                         },
                         activeColor: AppTheme.primaryBlue,
                         contentPadding: EdgeInsets.zero,
                       ),
                     ),
                     const SizedBox(height: 20),

                     // Semester Cards
                     _buildSemesterSection('Semester 1 Baseline', _sem1SgpaController, _sem1CreditsController, AppTheme.subjectBgColor('ADA')),
                    const SizedBox(height: 12),
                    _buildSemesterSection('Semester 2 Baseline', _sem2SgpaController, _sem2CreditsController, AppTheme.subjectBgColor('OS')),
                    const SizedBox(height: 12),
                    _buildSemesterSection('Semester 3 Baseline', _sem3SgpaController, _sem3CreditsController, AppTheme.subjectBgColor('SE')),
                    const SizedBox(height: 24),

                    // Reset Data Button (Material Red Button)
                    GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: Theme.of(context).colorScheme.surface,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            title: Text('Reset GradeIt?', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textColorPrimary)),
                            content: Text(
                              'This will delete all saved profile information and marks data. It cannot be undone.',
                              style: TextStyle(color: AppTheme.textColorSecondary),
                            ),
                            actions: [
                              TextButton(
                                child: Text('Cancel', style: TextStyle(color: AppTheme.textColorSecondary, fontWeight: FontWeight.bold)),
                                onPressed: () => Navigator.pop(context),
                              ),
                              TextButton(
                                child: const Text('Reset', style: TextStyle(color: AppTheme.accentRed, fontWeight: FontWeight.bold)),
                                onPressed: () {
                                  provider.resetAll();
                                  Navigator.pop(context);
                                  Navigator.pop(context);
                                },
                              ),
                            ],
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: AppTheme.accentRed.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.accentRed, width: 1.0),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.restart_alt_rounded, size: 18, color: AppTheme.accentRed),
                            SizedBox(width: 8),
                            Text(
                              'Reset Academic Data',
                              style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.accentRed, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Developer GitHub link section
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Developed by Arsh • BMSCE CSE',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textColorSecondary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          GestureDetector(
                            onTap: () async {
                              final url = Uri.parse('https://github.com/Arsh1255');
                              if (await canLaunchUrl(url)) {
                                await launchUrl(url, mode: LaunchMode.externalApplication);
                              } else {
                                Clipboard.setData(const ClipboardData(text: 'https://github.com/Arsh1255'));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Could not launch URL. Copied to clipboard!'),
                                    behavior: SnackBarBehavior.floating,
                                    backgroundColor: AppTheme.primaryBlue,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.code_rounded, size: 14, color: AppTheme.textColorSecondary),
                                const SizedBox(width: 4),
                                Text(
                                  'github.com/Arsh1255',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.primaryBlue,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
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

  Widget _buildSemesterSection(String title, TextEditingController sgpaController, TextEditingController creditsController, Color sectionColor) {
    return GlassCard(
      glowColor: Theme.of(context).colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: sectionColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textColorPrimary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildTextField(
                  controller: sgpaController,
                  label: 'SGPA',
                  icon: Icons.star_outline_rounded,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    final d = double.tryParse(v ?? '');
                    if (d == null || d < 0 || d > 10.0) return 'Invalid';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: _buildTextField(
                  controller: creditsController,
                  label: 'Credits',
                  icon: Icons.tag_rounded,
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    final i = int.tryParse(v ?? '');
                    if (i == null || i < 0) return 'Invalid';
                    return null;
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(fontSize: 13, color: AppTheme.textColorPrimary, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppTheme.textColorSecondary, fontSize: 10, fontWeight: FontWeight.w500),
        prefixIcon: Icon(icon, color: AppTheme.textColorSecondary, size: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppTheme.borderColor, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppTheme.accentRed, width: 1.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppTheme.accentRed, width: 2.0),
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
      ),
    );
  }
}
