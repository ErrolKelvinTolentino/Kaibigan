import 'package:flutter/material.dart';

import '../../../core/theme/kaibigan_tokens.dart';
import '../../../core/widgets/kaibigan_surface.dart';
import '../sleep_insights.dart';

/// Plots the estimated energy for the day after a logged night, and names the
/// peaks and dips in clock terms so the shape is actionable.
class SleepEnergyCurveCard extends StatelessWidget {
  const SleepEnergyCurveCard({super.key, required this.insights});

  final SleepInsights insights;

  @override
  Widget build(BuildContext context) {
    final palette = context.kaibigan;
    final text = Theme.of(context).textTheme;
    if (!insights.hasEnergyCurve) return const SizedBox.shrink();

    final peaks = insights.peaks;
    final dips = insights.dips;

    return KaibiganSurface(
      key: const ValueKey('sleep-energy-curve'),
      tone: KaibiganSurfaceTone.elevated,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      showShadow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.show_chart_rounded, size: 18, color: palette.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text('How today is likely to run', style: text.titleSmall),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Estimated from how long and how well you slept, plus the body '
            'clock most people share. A shape to plan around, not a reading.',
            style: text.bodySmall?.copyWith(
              color: palette.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 132,
            child: CustomPaint(
              size: Size.infinite,
              painter: _EnergyCurvePainter(
                points: insights.energyCurve,
                windows: insights.windows,
                line: palette.accentStrong,
                fill: palette.accentSubtle,
                grid: palette.border,
                peakMark: palette.botanical,
                dipMark: palette.warning,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                SleepInsights.formatDecimalHour(insights.energyCurve.first.hour),
                style: text.bodySmall?.copyWith(color: palette.textMuted),
              ),
              Text(
                SleepInsights.formatDecimalHour(insights.energyCurve.last.hour),
                style: text.bodySmall?.copyWith(color: palette.textMuted),
              ),
            ],
          ),
          if (peaks.isNotEmpty || dips.isNotEmpty) ...[
            const SizedBox(height: 14),
            Divider(color: palette.border, height: 1),
            const SizedBox(height: 12),
            ...[...peaks, ...dips].map(
              (window) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _WindowRow(window: window),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _WindowRow extends StatelessWidget {
  const _WindowRow({required this.window});

  final EnergyWindow window;

  @override
  Widget build(BuildContext context) {
    final palette = context.kaibigan;
    final text = Theme.of(context).textTheme;
    final isPeak = window.kind == EnergyWindowKind.peak;
    final colour = isPeak ? palette.botanical : palette.warning;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: colour.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(
            isPeak ? Icons.trending_up_rounded : Icons.trending_down_rounded,
            size: 17,
            color: colour,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${window.label} · '
                '${SleepInsights.formatDecimalHour(window.startHour)}'
                '–${SleepInsights.formatDecimalHour(window.endHour)}',
                style: text.labelLarge?.copyWith(color: colour),
              ),
              const SizedBox(height: 2),
              Text(
                window.suggestion,
                style: text.bodySmall?.copyWith(
                  color: palette.textSecondary,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EnergyCurvePainter extends CustomPainter {
  const _EnergyCurvePainter({
    required this.points,
    required this.windows,
    required this.line,
    required this.fill,
    required this.grid,
    required this.peakMark,
    required this.dipMark,
  });

  final List<EnergyPoint> points;
  final List<EnergyWindow> windows;
  final Color line;
  final Color fill;
  final Color grid;
  final Color peakMark;
  final Color dipMark;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final firstHour = points.first.hour;
    final lastHour = points.last.hour;
    final span = lastHour - firstHour;
    if (span <= 0) return;

    double dx(double hour) => (hour - firstHour) / span * size.width;
    // The curve is an estimate, so the axis is fixed at 0–100 rather than
    // stretched to the data. A flat day should look flat.
    double dy(double energy) =>
        size.height - (energy.clamp(0, 100) / 100) * size.height;

    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (final level in [25.0, 50.0, 75.0]) {
      final y = dy(level);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final path = Path()..moveTo(dx(points.first.hour), dy(points.first.energy));
    for (var i = 1; i < points.length; i++) {
      final previous = points[i - 1];
      final current = points[i];
      final midX = (dx(previous.hour) + dx(current.hour)) / 2;
      path.cubicTo(
        midX,
        dy(previous.energy),
        midX,
        dy(current.energy),
        dx(current.hour),
        dy(current.energy),
      );
    }

    final area = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(area, Paint()..color = fill);
    canvas.drawPath(
      path,
      Paint()
        ..color = line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    for (final window in windows) {
      final isPeak = window.kind == EnergyWindowKind.peak;
      final centre = Offset(dx(window.centreHour), dy(window.level));
      canvas.drawCircle(centre, 5.5, Paint()..color = Colors.white);
      canvas.drawCircle(
        centre,
        4.4,
        Paint()..color = isPeak ? peakMark : dipMark,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _EnergyCurvePainter oldDelegate) =>
      oldDelegate.points != points ||
      oldDelegate.windows != windows ||
      oldDelegate.line != line;
}
