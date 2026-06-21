import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/theme.dart';
import '../models/user_profile.dart';

class TrendChart extends StatelessWidget {
  final UserProfile profile;
  final double sem4Sgpa;
  final double sem4Cgpa;

  const TrendChart({
    super.key,
    required this.profile,
    required this.sem4Sgpa,
    required this.sem4Cgpa,
  });

  @override
  Widget build(BuildContext context) {
    // Collect semester data
    final sgpaData = [
      profile.sem1Sgpa > 0 ? profile.sem1Sgpa : 8.0,
      profile.sem2Sgpa > 0 ? profile.sem2Sgpa : 8.0,
      profile.sem3Sgpa > 0 ? profile.sem3Sgpa : 8.0,
      sem4Sgpa > 0 ? sem4Sgpa : 8.0,
    ];

    // Compute cumulative GPA at each semester step
    final pCredits = [
      profile.sem1Credits > 0 ? profile.sem1Credits : 20,
      profile.sem2Credits > 0 ? profile.sem2Credits : 20,
      profile.sem3Credits > 0 ? profile.sem3Credits : 20,
      22, // Sem 4 Credits
    ];

    double sumPoints = 0;
    int sumCredits = 0;
    final List<double> cgpaData = [];

    for (int i = 0; i < 4; i++) {
      sumPoints += sgpaData[i] * pCredits[i];
      sumCredits += pCredits[i];
      cgpaData.add(sumPoints / sumCredits);
    }

    final allValues = [...sgpaData, ...cgpaData];
    double minY = allValues.reduce((a, b) => a < b ? a : b) - 0.5;
    double maxY = allValues.reduce((a, b) => a > b ? a : b) + 0.5;
    minY = minY.clamp(0.0, 9.0);
    maxY = maxY.clamp(1.0, 10.0);

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          minY: minY,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false, // Cleaner Google style
            horizontalInterval: 1.0,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: AppTheme.borderColor.withOpacity(0.4),
                strokeWidth: 1.0,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1.0,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toStringAsFixed(1),
                    style: TextStyle(
                      color: AppTheme.textColorSecondary,
                      fontSize: 10,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  switch (value.toInt()) {
                    case 0:
                      return _bottomTitleText('Sem 1');
                    case 1:
                      return _bottomTitleText('Sem 2');
                    case 2:
                      return _bottomTitleText('Sem 3');
                    case 3:
                      return _bottomTitleText('Sem 4 (P)');
                  }
                  return const SizedBox();
                },
              ),
            ),
          ),
          borderData: FlBorderData(
            show: false, // Borderless M3
          ),
          lineBarsData: [
            // SGPA Curve - Google Blue (Smooth curved line)
            LineChartBarData(
              spots: [
                FlSpot(0, sgpaData[0]),
                FlSpot(1, sgpaData[1]),
                FlSpot(2, sgpaData[2]),
                FlSpot(3, sgpaData[3]),
              ],
              isCurved: true,
              curveMode: CurveMode.quadratic,
              color: AppTheme.primaryBlue,
              barWidth: 3.5,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                  radius: 4,
                  color: Colors.white,
                  strokeWidth: 3.0,
                  strokeColor: AppTheme.primaryBlue,
                ),
              ),
            ),
            // CGPA Curve - Google Green (Smooth dashed line)
            LineChartBarData(
              spots: [
                FlSpot(0, cgpaData[0]),
                FlSpot(1, cgpaData[1]),
                FlSpot(2, cgpaData[2]),
                FlSpot(3, cgpaData[3]),
              ],
              isCurved: true,
              curveMode: CurveMode.quadratic,
              color: AppTheme.accentGreen,
              barWidth: 3.0,
              isStrokeCapRound: true,
              dashArray: [5, 5],
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                  radius: 3.5,
                  color: Colors.white,
                  strokeWidth: 3.0,
                  strokeColor: AppTheme.accentGreen,
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              tooltipBgColor: Colors.white,
              tooltipBorder: BorderSide(color: AppTheme.borderColor, width: 1.0),
              tooltipRoundedRadius: 12,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((barSpot) {
                  final isSgpa = barSpot.barIndex == 0;
                  return LineTooltipItem(
                    '${isSgpa ? 'SGPA' : 'CGPA'}: ${barSpot.y.toStringAsFixed(2)}',
                    TextStyle(
                      color: isSgpa ? AppTheme.primaryBlue : AppTheme.accentGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _bottomTitleText(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Text(
        text,
        style: TextStyle(
          color: AppTheme.textColorSecondary,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
