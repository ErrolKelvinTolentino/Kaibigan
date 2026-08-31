import 'package:flutter/material.dart';

import '../theme/kaibigan_tokens.dart';
import 'kaibigan_logo.dart';

enum KaibiganStateTone { neutral, warm, botanical, error, success }

/// Calm loading, empty, error, and completion feedback shared by features.
class KaibiganStateView extends StatelessWidget {
  const KaibiganStateView({
    super.key,
    required this.title,
    required this.message,
    this.icon,
    this.actionLabel,
    this.onAction,
    this.tone = KaibiganStateTone.neutral,
    this.loading = false,
    this.compact = false,
  });

  final String title;
  final String message;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final KaibiganStateTone tone;
  final bool loading;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final palette = context.kaibigan;
    final accent = switch (tone) {
      KaibiganStateTone.botanical => palette.botanical,
      KaibiganStateTone.error => palette.danger,
      KaibiganStateTone.success => palette.success,
      _ => palette.accent,
    };
    return Semantics(
      liveRegion: loading || tone == KaibiganStateTone.error,
      label: '$title. $message',
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 14 : 24,
          vertical: compact ? 16 : 28,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (loading)
              KaibiganLoadingMark(color: accent)
            else
              Container(
                width: compact ? 52 : 70,
                height: compact ? 52 : 70,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(compact ? 18 : 24),
                ),
                child: icon == null
                    ? Padding(
                        padding: EdgeInsets.all(compact ? 10 : 14),
                        child: const KaibiganLogo(size: 42),
                      )
                    : Icon(icon, color: accent, size: compact ? 25 : 32),
              ),
            SizedBox(height: compact ? 13 : 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: palette.textSecondary),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 18),
              FilledButton.tonal(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class KaibiganLoadingMark extends StatefulWidget {
  const KaibiganLoadingMark({
    super.key,
    required this.color,
    this.compact = false,
  });

  final Color color;
  final bool compact;

  @override
  State<KaibiganLoadingMark> createState() => _KaibiganLoadingMarkState();
}

class _KaibiganLoadingMarkState extends State<KaibiganLoadingMark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
      _controller.value = 0.55;
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.compact ? 42 : 72,
      height: widget.compact ? 24 : 48,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            final phase = (_controller.value - (index * 0.18)) % 1;
            final strength = (1 - ((phase - 0.5).abs() * 2)).clamp(0.35, 1.0);
            return Padding(
              // Three compact marks must total 42px exactly (10 + 4 each).
              // The previous 6px horizontal padding caused a 6px overflow
              // inside narrow authentication buttons.
              padding: EdgeInsets.symmetric(horizontal: widget.compact ? 2 : 3),
              child: Transform.scale(
                scale: 0.78 + (strength * 0.22),
                child: Icon(
                  Icons.hexagon_rounded,
                  size: widget.compact ? 10 : 17,
                  color: widget.color.withValues(alpha: strength),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
