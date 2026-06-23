import 'dart:math';
import 'package:flutter/material.dart';
import '../core/theme.dart';

class GlassDial extends StatefulWidget {
  final double value; // Predicted/Current value (e.g. 8.4)
  final double maxValue; // Max possible value (e.g. 9.5)
  final double totalMax; // absolute maximum (e.g. 10.0)
  final String label; // "SGPA" or "CGPA"
  final Color activeColor;

  const GlassDial({
    super.key,
    required this.value,
    required this.maxValue,
    this.totalMax = 10.0,
    required this.label,
    this.activeColor = AppTheme.primaryBlue,
  });

  @override
  State<GlassDial> createState() => _GlassDialState();
}

class _GlassDialState extends State<GlassDial> with TickerProviderStateMixin {
  late AnimationController _valueController;
  late AnimationController _maxController;
  late Animation<double> _valueAnimation;
  late Animation<double> _maxAnimation;

  @override
  void initState() {
    super.initState();
    _valueController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _maxController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _valueAnimation = Tween<double>(begin: 0.0, end: widget.value).animate(
      CurvedAnimation(parent: _valueController, curve: Curves.easeOutCubic),
    );
    _maxAnimation = Tween<double>(begin: 0.0, end: widget.maxValue).animate(
      CurvedAnimation(parent: _maxController, curve: Curves.easeOutCubic),
    );

    _valueController.forward();
    _maxController.forward();
  }

  @override
  void didUpdateWidget(covariant GlassDial oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _valueAnimation = Tween<double>(
        begin: _valueAnimation.value,
        end: widget.value,
      ).animate(
        CurvedAnimation(parent: _valueController..reset()..forward(), curve: Curves.easeOutCubic),
      );
    }
    if (oldWidget.maxValue != widget.maxValue) {
      _maxAnimation = Tween<double>(
        begin: _maxAnimation.value,
        end: widget.maxValue,
      ).animate(
        CurvedAnimation(parent: _maxController..reset()..forward(), curve: Curves.easeOutCubic),
      );
    }
  }

  @override
  void dispose() {
    _valueController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_valueAnimation, _maxAnimation]),
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 130,
              height: 130,
              child: CustomPaint(
                painter: _M3DialPainter(
                  value: _valueAnimation.value,
                  maxValue: _maxAnimation.value,
                  totalMax: widget.totalMax,
                  activeColor: widget.activeColor,
                ),
              ),
            ),
            // Text values inside the dial
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.label.toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textColorSecondary,
                    fontSize: 9,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  _valueAnimation.value.toStringAsFixed(2),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textColorPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  'BEST: ${_maxAnimation.value.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: AppTheme.textColorSecondary,
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _M3DialPainter extends CustomPainter {
  final double value;
  final double maxValue;
  final double totalMax;
  final Color activeColor;

  _M3DialPainter({
    required this.value,
    required this.maxValue,
    required this.totalMax,
    required this.activeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2) - 6;

    const double startAngle = -pi / 2;
    const double sweepAngle = 2 * pi;

    final double valueRatio = (value / totalMax).clamp(0.0, 1.0);
    final double maxRatio = (maxValue / totalMax).clamp(0.0, 1.0);

    // 1. Base Track (Thin light gray line)
    final trackPaint = Paint()
      ..color = AppTheme.borderColor.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // 2. Max Possible Arc (Light accent color)
    if (maxRatio > 0.0) {
      final maxPaint = Paint()
        ..color = activeColor.withOpacity(0.24)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle * maxRatio,
        false,
        maxPaint,
      );
    }

    // 3. Current / Predicted Arc (Solid accent color)
    if (valueRatio > 0.0) {
      final activePaint = Paint()
        ..color = activeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle * valueRatio,
        false,
        activePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _M3DialPainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.maxValue != maxValue ||
        oldDelegate.totalMax != totalMax ||
        oldDelegate.activeColor != activeColor;
  }
}
