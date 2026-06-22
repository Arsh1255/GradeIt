import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:file_picker/file_picker.dart';
import '../core/theme.dart';
import '../models/semester.dart';
import '../models/generic_component.dart';
import '../services/academic_provider.dart';

class AcademicDataHelper {
  static void showExportBottomSheet(BuildContext context, AcademicProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
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
                            text: 'Grade It Academic Performance Report - ${provider.semester?.name ?? "Semester"}',
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
              
                    // Export .gradeit template
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.primaryBlue.withOpacity(0.12),
                        child: const Icon(Icons.file_download_outlined, color: AppTheme.primaryBlue),
                      ),
                      title: Text(
                        'Export Semester Template (.gradeit)',
                        style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textColorPrimary),
                      ),
                      subtitle: Text(
                        'Share this semester configuration structure with classmates.',
                        style: TextStyle(color: AppTheme.textColorSecondary, fontSize: 11),
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      onTap: () async {
                        HapticFeedback.lightImpact();
                        Navigator.pop(context);
                        
                        final semester = provider.semester;
                        if (semester != null) {
                          final exportedSubjects = semester.subjects.map((sub) {
                            List<GenericComponent> clearComponents(List<GenericComponent> list) {
                              return list.map((c) {
                                if (c.type == 'standalone') {
                                  return c.copyWith(
                                    scoredMarks: null,
                                    predictedMarks: 0.0,
                                    isCompleted: false,
                                    clearScoredMarks: true,
                                  );
                                } else {
                                  return c.copyWith(
                                    children: clearComponents(c.children),
                                  );
                                }
                              }).toList();
                            }
                            return sub.copyWith(components: clearComponents(sub.components));
                          }).toList();

                          final exportedSemester = semester.copyWith(subjects: exportedSubjects);
                          final jsonStr = exportedSemester.toJson();

                          try {
                            final directory = await getTemporaryDirectory();
                            final safeName = semester.name.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
                            final file = File('${directory.path}/$safeName.gradeit');
                            await file.writeAsString(jsonStr);
                            await Share.shareXFiles(
                              [XFile(file.path, mimeType: 'application/json')],
                              text: 'GradeIt Semester Template: ${semester.name}',
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to export template: $e')),
                            );
                          }
                        }
                      },
                    ),
                    const SizedBox(height: 8),

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
          ),
        );
      },
    );
  }

  static void showImportDialog(BuildContext parentContext, AcademicProvider provider) {
    showDialog(
      context: parentContext,
      builder: (dialogContext) {
        final textController = TextEditingController();
        return Dialog(
          backgroundColor: AppTheme.cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Import Semester Template',
                    style: TextStyle(color: AppTheme.textColorPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Load a semester structure shared by a classmate (.gradeit). All existing grades will be reset to pending.',
                    style: TextStyle(color: AppTheme.textColorSecondary, fontSize: 11),
                  ),
                  // Hide file picker when keyboard is open to prevent overflow
                  if (MediaQuery.of(dialogContext).viewInsets.bottom == 0) ...[
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          final result = await FilePicker.platform.pickFiles(
                            type: FileType.any,
                          );
                          if (result != null && result.files.single.path != null) {
                            final file = File(result.files.single.path!);
                            final content = await file.readAsString();
                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                              _importSemesterWithLoadingAndChecks(parentContext, provider, content);
                            }
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            SnackBar(content: Text('File picker error: \$e. Try pasting JSON below.')),
                          );
                        }
                      },
                      icon: const Icon(Icons.folder_open_rounded, size: 16),
                      label: const Text('Pick .gradeit File'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        'OR PASTE TEMPLATE CODE',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.textColorSecondary),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextField(
                    controller: textController,
                    maxLines: MediaQuery.of(dialogContext).viewInsets.bottom > 0 ? 2 : 4,
                    style: TextStyle(color: AppTheme.textColorPrimary, fontSize: 11),
                    decoration: InputDecoration(
                      hintText: 'Paste .gradeit JSON code here...',
                      hintStyle: TextStyle(color: AppTheme.textColorSecondary.withOpacity(0.5)),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          final text = textController.text.trim();
                          if (text.isNotEmpty) {
                            Navigator.pop(dialogContext);
                            _importSemesterWithLoadingAndChecks(parentContext, provider, text);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Import'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static List<String> _validateSemesterJson(Map<String, dynamic> data) {
    final errors = <String>[];

    if (data['name'] == null || data['name'].toString().trim().isEmpty) {
      errors.add("Missing or empty 'name' field for the Semester.");
    }
    
    if (data['subjects'] == null) {
      errors.add("Missing 'subjects' list.");
    } else if (data['subjects'] is! List) {
      errors.add("'subjects' must be a JSON array (list).");
    } else {
      final subjectsList = data['subjects'] as List;
      if (subjectsList.isEmpty) {
        errors.add("The 'subjects' list cannot be empty.");
      }
      
      for (int i = 0; i < subjectsList.length; i++) {
        final sub = subjectsList[i];
        if (sub is! Map<String, dynamic>) {
          errors.add("Subject at index $i is not a valid JSON object.");
          continue;
        }
        final sName = sub['name'] ?? '';
        final sCode = sub['code'] ?? '';
        final sCredits = sub['credits'];
        final sComponents = sub['components'] ?? sub['assessments'];
        
        final subLabel = sName.toString().isNotEmpty ? "'$sName' ($sCode)" : "Subject at index $i";
        
        if (sName.toString().trim().isEmpty) {
          errors.add("Subject at index $i is missing a 'name'.");
        }
        if (sCode.toString().trim().isEmpty) {
          errors.add("$subLabel is missing a 'code'.");
        }
        if (sCredits == null) {
          errors.add("$subLabel is missing 'credits'.");
        } else {
          final parsedCredits = int.tryParse(sCredits.toString());
          if (parsedCredits == null || parsedCredits <= 0) {
            errors.add("$subLabel must have credits greater than 0.");
          }
        }
        
        if (sComponents == null) {
          errors.add("$subLabel is missing 'components' list.");
        } else if (sComponents is! List) {
          errors.add("$subLabel 'components' must be a JSON array.");
        } else {
          final comps = sComponents as List;
          if (comps.isEmpty) {
            errors.add("$subLabel has no components defined.");
          }
          
          double totalWeight = 0.0;
          
          List<String> validateComponentList(List list, String parentPath) {
            final compErrors = <String>[];
            for (int j = 0; j < list.length; j++) {
              final c = list[j];
              if (c is! Map<String, dynamic>) {
                compErrors.add("$parentPath: Component at index $j is not a valid JSON object.");
                continue;
              }
              final cName = c['name'] ?? '';
              final cType = c['type'] ?? 'standalone';
              
              final cLabel = cName.toString().isNotEmpty ? "'$cName'" : "Component at index $j";
              
              if (cName.toString().trim().isEmpty) {
                compErrors.add("$parentPath: Component at index $j is missing a 'name'.");
              }
              
              if (cType != 'standalone' && cType != 'grouped') {
                compErrors.add("$parentPath: Component $cLabel must have type 'standalone' or 'grouped'.");
              }
              
              if (cType == 'standalone') {
                final maxMarks = c['maxMarks'];
                final weight = c['weight'];
                if (maxMarks == null || double.tryParse(maxMarks.toString()) == null || double.parse(maxMarks.toString()) <= 0) {
                  compErrors.add("$parentPath: Component $cLabel must have maxMarks > 0.");
                }
                if (weight == null || double.tryParse(weight.toString()) == null || double.parse(weight.toString()) < 0) {
                  compErrors.add("$parentPath: Component $cLabel must have a valid non-negative weight.");
                }
              } else if (cType == 'grouped') {
                final rule = c['selectionRule'];
                final children = c['children'];
                if (rule == null) {
                  compErrors.add("$parentPath: Grouped component $cLabel is missing a 'selectionRule'.");
                }
                if (children == null || children is! List || children.isEmpty) {
                  compErrors.add("$parentPath: Grouped component $cLabel must have a non-empty 'children' list.");
                } else {
                  compErrors.addAll(validateComponentList(children, "$parentPath -> $cLabel"));
                }
              }
            }
            return compErrors;
          }
          
          errors.addAll(validateComponentList(comps, subLabel));
          
          // Sum top-level component weights
          for (final c in comps) {
            if (c is Map<String, dynamic>) {
              final wStr = c['weight'] ?? '0';
              totalWeight += double.tryParse(wStr.toString()) ?? 0.0;
            }
          }
          
          if ((totalWeight - 100.0).abs() > 0.01) {
            errors.add("$subLabel component weights must sum to exactly 100 (currently: ${totalWeight.toStringAsFixed(1)}).");
          }
        }
      }
    }
    
    return errors;
  }

  static void showValidationAlert(BuildContext context, List<String> errors) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: AppTheme.accentRed, size: 24),
              const SizedBox(width: 8),
              Text(
                'Import Validation Failed',
                style: TextStyle(color: AppTheme.textColorPrimary, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: errors.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.accentRed)),
                      Expanded(
                        child: Text(
                          errors[index],
                          style: TextStyle(color: AppTheme.textColorSecondary, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
            ),
          ],
        );
      },
    );
  }

  static void _importSemesterWithLoadingAndChecks(BuildContext context, AcademicProvider provider, String jsonStr) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Row(
            children: [
              const CircularProgressIndicator(color: AppTheme.primaryBlue),
              const SizedBox(width: 20),
              Text(
                'Validating template...',
                style: TextStyle(color: AppTheme.textColorPrimary, fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
      },
    );

    await Future.delayed(const Duration(milliseconds: 800));

    if (context.mounted) {
      Navigator.pop(context);
    }

    try {
      final decoded = json.decode(jsonStr);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException("Root element must be a JSON object.");
      }

      final errors = _validateSemesterJson(decoded);
      if (errors.isNotEmpty) {
        if (context.mounted) {
          showValidationAlert(context, errors);
        }
        return;
      }

      final semester = Semester.fromJson(jsonStr);
      final resetSubjects = semester.subjects.map((sub) {
        List<GenericComponent> clearComponents(List<GenericComponent> list) {
          return list.map((c) {
            if (c.type == 'standalone') {
              return c.copyWith(
                scoredMarks: null,
                predictedMarks: 0.0,
                isCompleted: false,
                clearScoredMarks: true,
              );
            } else {
              return c.copyWith(
                children: clearComponents(c.children),
              );
            }
          }).toList();
        }
        return sub.copyWith(components: clearComponents(sub.components));
      }).toList();

      final resetSemester = semester.copyWith(subjects: resetSubjects);
      provider.createCustomSemester(resetSemester);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully imported "${semester.name}"!'),
            backgroundColor: AppTheme.accentGreen,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        showValidationAlert(context, [
          "Invalid JSON syntax or formatting error.",
          "Details: ${e.toString()}"
        ]);
      }
    }
  }

  static void _copyToClipboard(BuildContext context, String text, String label) {
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

  static String _generateCsv(AcademicProvider provider) {
    final buffer = StringBuffer();
    buffer.writeln('Subject Code,Subject Name,Credits,Predicted Score,Max Achievable,Marks Lost,Predicted Grade');
    for (final s in provider.subjects) {
      buffer.writeln('${s.code},"${s.name}",${s.credits},${s.predictedScore.toStringAsFixed(1)},${s.maxPossibleScore.toStringAsFixed(1)},${s.marksPermanentlyLost.toStringAsFixed(1)},${s.getPredictedGradeLetter(provider.gradeScheme)}');
    }
    buffer.writeln();
    buffer.writeln('${provider.semester?.name ?? "Active Semester"} Predicted SGPA,${provider.predictedSgpa.toStringAsFixed(3)}');
    buffer.writeln('${provider.semester?.name ?? "Active Semester"} Max SGPA,${provider.maxSgpa.toStringAsFixed(3)}');
    buffer.writeln('Cumulative CGPA,${provider.predictedCgpa.toStringAsFixed(3)}');
    return buffer.toString();
  }

  static String _generateMarkdown(AcademicProvider provider) {
    final buffer = StringBuffer();
    buffer.writeln('# Grade It Academic Performance Report');
    buffer.writeln('* **Student Name:** ${provider.userProfile.name}');
    buffer.writeln('* **USN:** ${provider.userProfile.usn}');
    buffer.writeln('* **Semester:** ${provider.semester?.name ?? "Active Semester"}');
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

  static String _generateTextSummary(AcademicProvider provider) {
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

  static Future<void> _sharePdfReport(BuildContext context, AcademicProvider provider) async {
    final pdf = pw.Document();

    // Load Lexend font from assets
    final ByteData fontData = await rootBundle.load('google_fonts/Lexend-Regular.ttf');
    final ttf = pw.Font.ttf(fontData);
    final ByteData fontDataBold = await rootBundle.load('google_fonts/Lexend-Bold.ttf');
    final ttfBold = pw.Font.ttf(fontDataBold);

    // Subtle geometric doodle SVG background
    const String backgroundSvg = '''
<svg viewBox="0 0 595 842" xmlns="http://www.w3.org/2000/svg">
  <g fill="none" stroke="#0B57D0" stroke-opacity="0.04" stroke-width="1.2">
    <circle cx="30" cy="30" r="22" />
    <circle cx="565" cy="812" r="22" />
    <circle cx="565" cy="30" r="14" />
    <circle cx="30" cy="812" r="14" />
    <rect x="520" y="60" width="40" height="40" transform="rotate(30 540 80)" />
    <rect x="20" y="740" width="35" height="35" transform="rotate(15 37 757)" />
    <polygon points="280,18 296,46 264,46" />
    <polygon points="315,820 331,796 299,796" />
    <path d="M 0 200 Q 40 180 80 200 T 160 200" stroke-width="1.5"/>
    <path d="M 435 640 Q 475 620 515 640 T 595 640" stroke-width="1.5"/>
    <line x1="550" y1="120" x2="595" y2="120" stroke-width="1"/>
    <line x1="550" y1="130" x2="595" y2="130" stroke-width="1"/>
    <line x1="0" y1="710" x2="45" y2="710" stroke-width="1"/>
    <line x1="0" y1="720" x2="45" y2="720" stroke-width="1"/>
  </g>
  <g fill="#0B57D0" fill-opacity="0.025">
    <circle cx="297" cy="80" r="60" />
    <circle cx="297" cy="762" r="60" />
  </g>
</svg>
''';

    final headers = ['Code', 'Subject Name', 'Credits', 'Predicted', 'Grade'];
    final data = provider.subjects.map((s) => [
      s.code,
      s.name,
      s.credits.toString(),
      '${s.predictedScore.toStringAsFixed(1)}%',
      s.getPredictedGradeLetter(provider.gradeScheme),
    ]).toList();

    final collegeName = provider.semester?.collegeName ?? '';
    final branchName = provider.semester?.branchName ?? '';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(36, 36, 36, 36),
        theme: pw.ThemeData.withFont(base: ttf, bold: ttfBold),
        build: (pw.Context ctx) {
          return pw.Stack(
            children: [
              // Doodle background
              pw.Positioned.fill(
                child: pw.SvgImage(svg: backgroundSvg),
              ),
              // Page content
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // ── Header ──
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: const pw.BoxDecoration(
                      color: PdfColor.fromInt(0xFF0B57D0),
                      borderRadius: pw.BorderRadius.all(pw.Radius.circular(10)),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'GradeIt',
                              style: pw.TextStyle(font: ttfBold, fontSize: 22, color: PdfColors.white),
                            ),
                            pw.Text(
                              'Academic Performance Report',
                              style: pw.TextStyle(font: ttf, fontSize: 10, color: const PdfColor(1, 1, 1, 0.72)),
                            ),
                          ],
                        ),
                        pw.Text(
                          DateTime.now().toLocal().toString().split(' ')[0],
                          style: pw.TextStyle(font: ttf, fontSize: 10, color: const PdfColor(1, 1, 1, 0.72)),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 18),

                  // ── Student Profile ──
                  pw.Container(
                    padding: const pw.EdgeInsets.all(14),
                    decoration: pw.BoxDecoration(
                      color: const PdfColor.fromInt(0xFFF5F9FF),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                      border: pw.Border.all(color: const PdfColor.fromInt(0xFFDDE5F5), width: 0.8),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('STUDENT PROFILE',
                            style: pw.TextStyle(font: ttfBold, fontSize: 8, color: PdfColors.grey600, letterSpacing: 1.2)),
                        pw.SizedBox(height: 8),
                        pw.Row(
                          children: [
                            pw.Expanded(
                              child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                                pw.Text('Name', style: pw.TextStyle(font: ttf, fontSize: 9, color: PdfColors.grey500)),
                                pw.Text(provider.userProfile.name,
                                    style: pw.TextStyle(font: ttfBold, fontSize: 12, color: PdfColors.grey900)),
                              ]),
                            ),
                            pw.Expanded(
                              child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                                pw.Text('USN', style: pw.TextStyle(font: ttf, fontSize: 9, color: PdfColors.grey500)),
                                pw.Text(provider.userProfile.usn,
                                    style: pw.TextStyle(font: ttfBold, fontSize: 12, color: PdfColors.grey900)),
                              ]),
                            ),
                          ],
                        ),
                        if (collegeName.isNotEmpty || branchName.isNotEmpty) ...[
                          pw.SizedBox(height: 8),
                          pw.Row(
                            children: [
                              if (collegeName.isNotEmpty)
                                pw.Expanded(
                                  child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                                    pw.Text('College', style: pw.TextStyle(font: ttf, fontSize: 9, color: PdfColors.grey500)),
                                    pw.Text(collegeName,
                                        style: pw.TextStyle(font: ttfBold, fontSize: 11, color: PdfColors.grey800)),
                                  ]),
                                ),
                              if (branchName.isNotEmpty)
                                pw.Expanded(
                                  child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                                    pw.Text('Branch', style: pw.TextStyle(font: ttf, fontSize: 9, color: PdfColors.grey500)),
                                    pw.Text(branchName,
                                        style: pw.TextStyle(font: ttfBold, fontSize: 11, color: PdfColors.grey800)),
                                  ]),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 18),

                  // ── Subject Table ──
                  pw.Text('SUBJECT BREAKDOWN',
                      style: pw.TextStyle(font: ttfBold, fontSize: 8, color: PdfColors.grey600, letterSpacing: 1.2)),
                  pw.SizedBox(height: 6),
                  pw.TableHelper.fromTextArray(
                    headers: headers,
                    data: data,
                    border: pw.TableBorder.all(color: const PdfColor.fromInt(0xFFE8ECF4), width: 0.6),
                    headerStyle: pw.TextStyle(font: ttfBold, fontSize: 9, color: PdfColors.white),
                    cellStyle: pw.TextStyle(font: ttf, fontSize: 9),
                    headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF0B57D0)),
                    rowDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF9FBFF)),
                    oddRowDecoration: const pw.BoxDecoration(color: PdfColors.white),
                    cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    cellAlignment: pw.Alignment.centerLeft,
                    columnWidths: {
                      0: const pw.FixedColumnWidth(50),
                      1: const pw.FlexColumnWidth(3),
                      2: const pw.FixedColumnWidth(45),
                      3: const pw.FixedColumnWidth(60),
                      4: const pw.FixedColumnWidth(40),
                    },
                  ),
                  pw.SizedBox(height: 18),

                  // ── SGPA / CGPA Summary ──
                  pw.Container(
                    padding: const pw.EdgeInsets.all(14),
                    decoration: pw.BoxDecoration(
                      color: const PdfColor.fromInt(0xFFF0F5FF),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                      border: pw.Border.all(color: const PdfColor.fromInt(0xFFBFD0F7), width: 0.8),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                          pw.Text('PREDICTED SGPA',
                              style: pw.TextStyle(font: ttfBold, fontSize: 8, color: PdfColors.grey500, letterSpacing: 0.8)),
                          pw.SizedBox(height: 3),
                          pw.Text('${provider.predictedSgpa.toStringAsFixed(3)} / 10.0',
                              style: pw.TextStyle(font: ttfBold, fontSize: 18, color: const PdfColor.fromInt(0xFF0B57D0))),
                        ]),
                        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
                          pw.Text('MAX ACHIEVABLE SGPA',
                              style: pw.TextStyle(font: ttfBold, fontSize: 8, color: PdfColors.grey500, letterSpacing: 0.8)),
                          pw.SizedBox(height: 3),
                          pw.Text('${provider.maxSgpa.toStringAsFixed(3)} / 10.0',
                              style: pw.TextStyle(font: ttfBold, fontSize: 18, color: const PdfColor.fromInt(0xFF137333))),
                        ]),
                        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                          pw.Text('CUMULATIVE CGPA',
                              style: pw.TextStyle(font: ttfBold, fontSize: 8, color: PdfColors.grey500, letterSpacing: 0.8)),
                          pw.SizedBox(height: 3),
                          pw.Text(provider.predictedCgpa.toStringAsFixed(3),
                              style: pw.TextStyle(font: ttfBold, fontSize: 18, color: const PdfColor.fromInt(0xFF006064))),
                        ]),
                      ],
                    ),
                  ),

                  pw.Spacer(),

                  // ── Footer ──
                  pw.Divider(color: PdfColors.grey300, thickness: 0.5),
                  pw.SizedBox(height: 4),
                  pw.Center(
                    child: pw.Text(
                      'Generated by GradeIt  •  Grades are simulated predictions, not official results.',
                      style: pw.TextStyle(font: ttf, fontSize: 7, color: PdfColors.grey400),
                    ),
                  ),
                ],
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
        text: 'GradeIt Academic Performance Report',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share PDF: $e')),
        );
      }
    }
  }
}
