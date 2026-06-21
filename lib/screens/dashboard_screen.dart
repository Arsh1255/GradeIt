import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../core/theme.dart';
import '../models/subject.dart';
import '../services/academic_provider.dart';
import '../widgets/glass_card.dart';
import '../widgets/glass_dial.dart';
import '../widgets/mesh_gradient_background.dart';
import 'subject_detail_screen.dart';
import 'profile_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MeshGradientBackground(
      child: Consumer<AcademicProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- SAMSUNG ONE UI TOP HEADER SECTION ---
              
              Padding(
                padding: const EdgeInsets.fromLTRB(24.0, 32.0, 24.0, 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'GradeIt',
                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textColorPrimary,
                                fontSize: 32,
                                letterSpacing: -1.0,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${provider.userProfile.name} • Sem 4 CSE',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textColorSecondary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                        ),
                      ],
                    ),
                    
                    // One UI Style Top Action Buttons
                    Row(
                      children: [
                        // Export Button
                        IconButton.filledTonal(
                          style: IconButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue.withOpacity(0.08),
                            foregroundColor: AppTheme.primaryBlue,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.all(10),
                          ),
                          icon: const Icon(Icons.ios_share_rounded, size: 20),
                          tooltip: 'Export Report',
                          onPressed: () => _showExportBottomSheet(context, provider),
                        ),
                        const SizedBox(width: 8),
                        
                        // Dark Mode Button
                        IconButton.filledTonal(
                          style: IconButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue.withOpacity(0.08),
                            foregroundColor: AppTheme.primaryBlue,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.all(10),
                          ),
                          icon: Icon(
                            provider.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                            size: 20,
                          ),
                          tooltip: 'Toggle Theme',
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            provider.toggleDarkMode();
                          },
                        ),
                        const SizedBox(width: 8),
                        
                        // Settings Button
                        IconButton.filledTonal(
                          style: IconButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue.withOpacity(0.08),
                            foregroundColor: AppTheme.primaryBlue,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.all(10),
                          ),
                          icon: const Icon(Icons.settings_rounded, size: 20),
                          tooltip: 'Settings',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const ProfileScreen()),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // GPA Dials Card (One UI Rounded corners 24dp)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 6.0),
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
                      Container(
                        width: 1.0,
                        height: 70,
                        color: AppTheme.borderColor,
                      ),
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
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
                child: Row(
                  children: [
                    // Semester Completion Card
                    Expanded(
                      child: GlassCard(
                        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 14.0),
                        borderRadius: 24,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Completion',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                                color: AppTheme.textColorSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${provider.semesterCompletionPercentage.toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textColorPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 5,
                              decoration: BoxDecoration(
                                color: AppTheme.borderColor.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(2.5),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(2.5),
                                child: LinearProgressIndicator(
                                  value: provider.semesterCompletionPercentage / 100,
                                  backgroundColor: Colors.transparent,
                                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Lost Marks Card
                    Expanded(
                      child: GlassCard(
                        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 14.0),
                        borderRadius: 24,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Lost Marks',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                  color: AppTheme.textColorSecondary,
                                ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              provider.totalMarksLost.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: provider.totalMarksLost > 15
                                    ? AppTheme.accentRed
                                    : AppTheme.textColorPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Out of 800 total',
                              style: TextStyle(
                                fontSize: 9,
                                color: AppTheme.textColorSecondary.withOpacity(0.8),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Achievable Marks Card
                    Expanded(
                      child: GlassCard(
                        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 14.0),
                        borderRadius: 24,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Achievable',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                                color: AppTheme.textColorSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              provider.totalRemainingAchievable.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textColorPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Pending marks',
                              style: TextStyle(
                                fontSize: 9,
                                color: AppTheme.textColorSecondary.withOpacity(0.8),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
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
                            Text(
                              'Course Targets',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 17,
                                    color: AppTheme.textColorPrimary,
                                  ),
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
                          children: provider.subjects.map((sub) => _buildSubjectCard(context, sub, provider)).toList(),
                        ),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSubjectCard(BuildContext context, Subject subject, AcademicProvider provider) {
    final bgTint = AppTheme.subjectBgColor(subject.code);
    final textTint = AppTheme.subjectTextColor(subject.code);
    final icon = AppTheme.subjectIcon(subject.code);

    return Container(
      margin: const EdgeInsets.only(bottom: 10.0),
      child: GlassCard(
        padding: EdgeInsets.zero,
        borderRadius: 20, // Clean rounded card
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SubjectDetailScreen(subjectCode: subject.code),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            children: [
              // Subject Icon Ring
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: bgTint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: textTint,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              
              // Name and Credits Details
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
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${subject.code} • ${subject.credits} Credits',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textColorSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Predicted Score Badge
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${subject.predictedScore.toStringAsFixed(0)}/100',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textColorPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: bgTint,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Grade ${subject.getPredictedGradeLetter(provider.gradeScheme)}',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: textTint,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- ONE UI EXPORT BOTTOM SHEET MODAL ---
  
  void _showExportBottomSheet(BuildContext context, AcademicProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (context, scrollController) {
            return SafeArea(
              child: SingleChildScrollView(
                controller: scrollController,
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Drag handle
                      Center(
                        child: Container(
                          width: 44,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppTheme.borderColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Export Academic Data',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textColorPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Choose format to share or copy academic standings to clipboard.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textColorSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      
                      // Primary Action 1: Share PDF Report
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[700],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.picture_as_pdf_rounded),
                        label: const Text(
                          'Share PDF Report (.pdf)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        onPressed: () async {
                          HapticFeedback.mediumImpact();
                          await _sharePdfReport(context, provider);
                          Navigator.pop(context);
                        },
                      ),
                      const SizedBox(height: 10),

                      // Primary Action 2: Share Spreadsheet File
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.table_chart_rounded),
                        label: const Text(
                          'Share Spreadsheet File (.csv)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        onPressed: () async {
                          HapticFeedback.mediumImpact();
                          final csv = _generateCsv(provider);
                          try {
                            final directory = await getTemporaryDirectory();
                            final file = File('${directory.path}/gradeit_semester_report.csv');
                            await file.writeAsString(csv);
                            await Share.shareXFiles(
                              [XFile(file.path, mimeType: 'text/csv')],
                              text: 'Grade It Academic Performance Report - Sem 4 CSE',
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to share file: $e')),
                            );
                          }
                          Navigator.pop(context);
                        },
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),
                
                // Copy CSV (Excel / Sheets)
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green.withOpacity(0.12),
                    child: const Icon(Icons.table_view_rounded, color: Colors.green),
                  ),
                  title: Text(
                    'Copy CSV Format (Excel)',
                    style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textColorPrimary),
                  ),
                  subtitle: Text(
                    'Perfect drop-in format for Excel or Google Sheets.',
                    style: TextStyle(color: AppTheme.textColorSecondary, fontSize: 11),
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    final csv = _generateCsv(provider);
                    _copyToClipboard(context, csv, 'CSV Report (.xlsx ready)');
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(height: 8),
                
                // Copy Markdown (Notion)
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primaryBlue.withOpacity(0.12),
                    child: const Icon(Icons.article_rounded, color: AppTheme.primaryBlue),
                  ),
                  title: Text(
                    'Copy Markdown Table (Notion)',
                    style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textColorPrimary),
                  ),
                  subtitle: Text(
                    'Formatted rich table for Notion or Obsidian.',
                    style: TextStyle(color: AppTheme.textColorSecondary, fontSize: 11),
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    final md = _generateMarkdown(provider);
                    _copyToClipboard(context, md, 'Markdown Table');
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(height: 8),
                
                // Copy plain text summary
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.accentYellow.withOpacity(0.12),
                    child: const Icon(Icons.copy_all_rounded, color: AppTheme.accentYellow),
                  ),
                  title: Text(
                    'Copy Text Summary (WhatsApp)',
                    style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textColorPrimary),
                  ),
                  subtitle: Text(
                    'Clean summary list for messages and sharing.',
                    style: TextStyle(color: AppTheme.textColorSecondary, fontSize: 11),
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    final txt = _generateTextSummary(provider);
                    _copyToClipboard(context, txt, 'Text Summary');
                    Navigator.pop(context);
                  },
                ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('$label copied to clipboard!'),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.primaryBlue,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  String _generateCsv(AcademicProvider provider) {
    final buffer = StringBuffer();
    buffer.writeln('Subject Code,Subject Name,Credits,Predicted Score,Max Achievable,Marks Lost,Predicted Grade');
    for (final s in provider.subjects) {
      buffer.writeln('${s.code},"${s.name}",${s.credits},${s.predictedScore.toStringAsFixed(1)},${s.maxPossibleScore.toStringAsFixed(1)},${s.marksPermanentlyLost.toStringAsFixed(1)},${s.getPredictedGradeLetter(provider.gradeScheme)}');
    }
    buffer.writeln();
    buffer.writeln('Semester 4 Predicted SGPA,${provider.predictedSgpa.toStringAsFixed(3)}');
    buffer.writeln('Semester 4 Max SGPA,${provider.maxSgpa.toStringAsFixed(3)}');
    buffer.writeln('Cumulative CGPA (Sem 1-4),${provider.predictedCgpa.toStringAsFixed(3)}');
    return buffer.toString();
  }

  String _generateMarkdown(AcademicProvider provider) {
    final buffer = StringBuffer();
    buffer.writeln('# Grade It Academic Performance Report');
    buffer.writeln('* **Student Name:** ${provider.userProfile.name}');
    buffer.writeln('* **USN:** ${provider.userProfile.usn}');
    buffer.writeln('* **Predicted SGPA:** ${provider.predictedSgpa.toStringAsFixed(3)} / 10.0');
    buffer.writeln('* **Max SGPA:** ${provider.maxSgpa.toStringAsFixed(3)} / 10.0');
    buffer.writeln('* **Overall CGPA:** ${provider.predictedCgpa.toStringAsFixed(3)}');
    buffer.writeln('\n## Subject Breakdown');
    buffer.writeln('| Code | Subject Name | Credits | Predicted Score | Max Achievable | Lost Marks | Grade |');
    buffer.writeln('|------|--------------|---------|-----------------|----------------|------------|-------|');
    for (final s in provider.subjects) {
      buffer.writeln('| ${s.code} | ${s.name} | ${s.credits} | ${s.predictedScore.toStringAsFixed(1)}% | ${s.maxPossibleScore.toStringAsFixed(1)}% | ${s.marksPermanentlyLost.toStringAsFixed(1)} | ${s.getPredictedGradeLetter(provider.gradeScheme)} |');
    }
    return buffer.toString();
  }

  String _generateTextSummary(AcademicProvider provider) {
    final buffer = StringBuffer();
    buffer.writeln('Grade It Summary Report');
    buffer.writeln('----------------------');
    buffer.writeln('Name: ${provider.userProfile.name}');
    buffer.writeln('USN: ${provider.userProfile.usn}');
    buffer.writeln('Predicted SGPA: ${provider.predictedSgpa.toStringAsFixed(3)}/10.0');
    buffer.writeln('Max Achievable SGPA: ${provider.maxSgpa.toStringAsFixed(3)}/10.0');
    buffer.writeln('Cumulative CGPA: ${provider.predictedCgpa.toStringAsFixed(3)}');
    buffer.writeln('\nSubjects Status:');
    for (final s in provider.subjects) {
      buffer.writeln('- ${s.code}: ${s.predictedScore.toStringAsFixed(1)}% (${s.getPredictedGradeLetter(provider.gradeScheme)}) | Credits: ${s.credits}');
    }
    return buffer.toString();
  }

  Future<void> _sharePdfReport(BuildContext context, AcademicProvider provider) async {
    final pdf = pw.Document();
    
    final headers = ['Subject Code', 'Subject Name', 'Credits', 'Predicted Score', 'Grade'];
    final data = provider.subjects.map((s) => [
      s.code,
      s.name,
      s.credits.toString(),
      '${s.predictedScore.toStringAsFixed(1)}%',
      s.getPredictedGradeLetter(provider.gradeScheme)
    ]).toList();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Grade It - Semester Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Sem 4 CSE', style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text('Student Profile Details:', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.Text('Name: ${provider.userProfile.name}', style: const pw.TextStyle(fontSize: 12)),
              pw.Text('USN: ${provider.userProfile.usn}', style: const pw.TextStyle(fontSize: 12)),
              pw.SizedBox(height: 20),
              pw.Text('Subject Breakdown:', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.TableHelper.fromTextArray(
                headers: headers,
                data: data,
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                cellStyle: const pw.TextStyle(fontSize: 10),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
                cellAlignment: pw.Alignment.centerLeft,
              ),
              pw.SizedBox(height: 30),
              pw.Divider(color: PdfColors.grey300, thickness: 0.5),
              pw.SizedBox(height: 15),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Predicted SGPA: ${provider.predictedSgpa.toStringAsFixed(3)} / 10.0', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Max Achievable SGPA: ${provider.maxSgpa.toStringAsFixed(3)} / 10.0', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Cumulative CGPA (Sem 1-4): ${provider.predictedCgpa.toStringAsFixed(3)}', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              pw.Spacer(),
              pw.Align(
                alignment: pw.Alignment.center,
                child: pw.Text('Generated by Grade It on ${DateTime.now().toLocal().toString().split(' ')[0]}', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
              ),
            ],
          );
        },
      ),
    );

    try {
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/gradeit_semester_report.pdf');
      await file.writeAsBytes(await pdf.save());
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/pdf')],
        text: 'Grade It Academic Performance Report - Sem 4 CSE',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to share PDF: $e')),
      );
    }
  }
}
