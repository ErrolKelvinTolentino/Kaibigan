import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../theme/journal_appearance.dart';

/// A calm, reusable writing surface shared by Journal and Reflection.
class JournalPaperSurface extends StatelessWidget {
  const JournalPaperSurface({
    super.key,
    required this.child,
    required this.style,
    required this.accentColor,
    this.padding = const EdgeInsets.fromLTRB(18, 24, 18, 20),
    this.showBinding = true,
    this.minHeight,
  });

  final Widget child;
  final JournalPaperStyle style;
  final Color accentColor;
  final EdgeInsetsGeometry padding;
  final bool showBinding;
  final double? minHeight;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final paperColor = isDark
        ? Color.alphaBlend(
            accentColor.withValues(alpha: 0.025),
            const Color(0xFF252B27),
          )
        : Color.alphaBlend(
            accentColor.withValues(alpha: 0.018),
            const Color(0xFFFFFEFA),
          );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        RepaintBoundary(
          child: Container(
            constraints: BoxConstraints(minHeight: minHeight ?? 0),
            decoration: BoxDecoration(
              color: paperColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark
                    ? AppColors.darkCardBorder
                    : Color.alphaBlend(
                        accentColor.withValues(alpha: 0.10),
                        const Color(0xFFE8DFD0),
                      ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.07),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(23),
              child: CustomPaint(
                painter: _JournalPaperPainter(
                  style: style,
                  accentColor: accentColor,
                  isDark: isDark,
                ),
                child: Padding(padding: padding, child: child),
              ),
            ),
          ),
        ),
        if (showBinding)
          Positioned(
            top: -7,
            left: 38,
            right: 38,
            child: IgnorePointer(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  5,
                  (_) => Container(
                    width: 9,
                    height: 18,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF59625C)
                          : const Color(0xFFD7C9B4),
                      borderRadius: BorderRadius.circular(99),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.10),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _JournalPaperPainter extends CustomPainter {
  const _JournalPaperPainter({
    required this.style,
    required this.accentColor,
    required this.isDark,
  });

  final JournalPaperStyle style;
  final Color accentColor;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final quiet = isDark ? 0.055 : 0.09;
    final patternPaint = Paint()
      ..color = accentColor.withValues(alpha: quiet)
      ..strokeWidth = 1;

    switch (style) {
      case JournalPaperStyle.clean:
        final glow = Paint()
          ..shader = RadialGradient(
            colors: [
              accentColor.withValues(alpha: isDark ? 0.035 : 0.045),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width, 0),
              radius: math.max(size.width, size.height) * 0.72,
            ),
          );
        canvas.drawRect(Offset.zero & size, glow);
        break;
      case JournalPaperStyle.ruled:
        const lineHeight = 28.0;
        for (double y = 72; y < size.height; y += lineHeight) {
          canvas.drawLine(
              Offset(16, y), Offset(size.width - 16, y), patternPaint);
        }
        final marginPaint = Paint()
          ..color = accentColor.withValues(alpha: isDark ? 0.08 : 0.11)
          ..strokeWidth = 1;
        canvas.drawLine(
            const Offset(12, 0), Offset(12, size.height), marginPaint);
        break;
      case JournalPaperStyle.dotted:
        const gap = 22.0;
        for (double y = 18; y < size.height; y += gap) {
          for (double x = 18; x < size.width; x += gap) {
            canvas.drawCircle(Offset(x, y), 1.05, patternPaint);
          }
        }
        break;
      case JournalPaperStyle.botanical:
        _paintSprig(canvas, Offset(size.width - 22, 20), patternPaint, -1);
        _paintSprig(canvas, Offset(18, size.height - 18), patternPaint, 1);
        break;
    }
  }

  void _paintSprig(
    Canvas canvas,
    Offset origin,
    Paint paint,
    double direction,
  ) {
    final path = Path()
      ..moveTo(origin.dx, origin.dy)
      ..quadraticBezierTo(
        origin.dx - (24 * direction),
        origin.dy + 30,
        origin.dx - (12 * direction),
        origin.dy + 66,
      );
    canvas.drawPath(path, paint..style = PaintingStyle.stroke);
    for (var index = 1; index <= 3; index++) {
      final center = Offset(
        origin.dx - (8 * index * direction),
        origin.dy + (16.0 * index),
      );
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(direction * 0.58);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: 15, height: 7),
        paint..style = PaintingStyle.fill,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _JournalPaperPainter oldDelegate) {
    return oldDelegate.style != style ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.isDark != isDark;
  }
}
