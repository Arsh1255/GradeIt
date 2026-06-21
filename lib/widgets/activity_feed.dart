import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../services/academic_provider.dart';

class ActivityFeed extends StatefulWidget {
  final AcademicProvider provider;

  const ActivityFeed({super.key, required this.provider});

  @override
  State<ActivityFeed> createState() => _ActivityFeedState();
}

class _ActivityFeedState extends State<ActivityFeed> {
  int _activeTab = 0; // 0 = Insights, 1 = Log

  @override
  Widget build(BuildContext context) {
    final insights = widget.provider.academicInsights;
    final logs = widget.provider.activities;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.borderColor,
          width: 1.0,
        ),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // M3 Tab bar header
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AppTheme.borderColor,
                  width: 1.0,
                ),
              ),
            ),
            child: Row(
              children: [
                _buildTabButton(0, 'Insights', Icons.lightbulb_outline_rounded),
                const SizedBox(width: 8),
                _buildTabButton(1, 'Activity', Icons.analytics_outlined),
              ],
            ),
          ),
          
          // Tab Content
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: Container(
              constraints: const BoxConstraints(maxHeight: 280),
              child: _activeTab == 0
                  ? _buildInsightsList(insights)
                  : _buildLogsList(logs),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, String label, IconData icon) {
    final isActive = _activeTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: isActive ? AppTheme.primaryBlue.withOpacity(0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isActive ? AppTheme.primaryBlue : AppTheme.textColorSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  color: isActive ? AppTheme.primaryBlue : AppTheme.textColorSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInsightsList(List<String> insights) {
    if (insights.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text('No insights generated yet.'),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.all(12),
      itemCount: insights.length,
      itemBuilder: (context, index) {
        final text = insights[index];
        
        Color iconBg = AppTheme.borderColor.withOpacity(0.4);
        Color iconColor = AppTheme.textColorSecondary;
        IconData itemIcon = Icons.info_outline_rounded;

        if (text.contains('🏆') || text.contains('Exceptional')) {
          iconBg = const Color(0xFFFEF7E0);
          iconColor = const Color(0xFFB06000);
          itemIcon = Icons.emoji_events_outlined;
        } else if (text.contains('🎯') || text.contains('Boundary')) {
          iconBg = const Color(0xFFE8F0FE);
          iconColor = const Color(0xFF1A73E8);
          itemIcon = Icons.track_changes_outlined;
        } else if (text.contains('⚠️') || text.contains('Risk')) {
          iconBg = const Color(0xFFFCE8E6);
          iconColor = const Color(0xFFC5221F);
          itemIcon = Icons.warning_amber_rounded;
        } else if (text.contains('🔍') || text.contains('Impact')) {
          iconBg = const Color(0xFFF3E8FF);
          iconColor = const Color(0xFF681DA8);
          itemIcon = Icons.search_outlined;
        }

        // Clean up the text
        String displayTest = text;
        if (text.length > 2) {
          final prefix = text.substring(0, 2);
          if (prefix == '🏆' || prefix == '🎯' || prefix == '⚠️' || prefix == '🔍' || prefix == '🌟' || prefix == '📈' || prefix == '📱') {
            displayTest = text.substring(2).trim();
          }
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.borderColor.withOpacity(0.6),
              width: 1.0,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  itemIcon,
                  size: 16,
                  color: iconColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  displayTest,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: AppTheme.textColorPrimary,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLogsList(List<String> logs) {
    if (logs.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text('No logged activities yet.'),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final text = logs[index];
        
        String time = '';
        String description = text;
        if (text.startsWith('[') && text.contains(']')) {
          final closeIndex = text.indexOf(']');
          time = text.substring(1, closeIndex);
          description = text.substring(closeIndex + 1).trim();
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (time.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.borderColor.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    time,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textColorSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textColorPrimary,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
