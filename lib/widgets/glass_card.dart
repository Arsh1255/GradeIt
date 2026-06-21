import 'package:flutter/material.dart';
import '../core/theme.dart';

class GlassCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Color? glowColor; // Serves as the card background fill color if provided
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16.0),
    this.borderRadius = 16.0,
    this.glowColor,
    this.onTap,
  });

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard> with SingleTickerProviderStateMixin {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bool isPressable = widget.onTap != null;
    final theme = Theme.of(context);

    Widget cardContent = AnimatedScale(
      scale: _isPressed ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOutCubic,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: widget.glowColor ?? theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(
            color: AppTheme.borderColor,
            width: 1.0,
          ),
          boxShadow: AppTheme.softShadow,
        ),
        child: Padding(
          padding: widget.padding,
          child: widget.child,
        ),
      ),
    );

    if (isPressable) {
      return GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: cardContent,
      );
    }

    return cardContent;
  }
}
