import 'package:flutter/material.dart';

/// The shared Kaibigan bee mark.
///
/// The source artwork is square with transparent corners, so it should keep
/// its aspect ratio and should not be clipped into another shape.
class KaibiganLogo extends StatelessWidget {
  const KaibiganLogo({
    super.key,
    required this.size,
    this.semanticLabel = 'Kaibigan logo',
  });

  static const assetPath = 'assets/Kaibigan Logo.png';

  final double size;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);
    return SizedBox.square(
      dimension: size,
      child: Image.asset(
        assetPath,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        isAntiAlias: true,
        gaplessPlayback: true,
        cacheWidth: (size * pixelRatio * 1.5).ceil().clamp(1, 2000).toInt(),
        cacheHeight: (size * pixelRatio * 1.5).ceil().clamp(1, 2000).toInt(),
        semanticLabel: semanticLabel,
      ),
    );
  }
}

/// The Kaibigan wordmark used beside the bee mark.
///
/// Only the letters "ai" carry the bee-yellow brand accent. The remaining
/// letters follow the current foreground color so the mark stays legible in
/// both light and night themes.
class KaibiganWordmark extends StatelessWidget {
  const KaibiganWordmark({
    super.key,
    this.fontSize = 22,
    this.foregroundColor,
  });

  final double fontSize;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final fallback = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFF3F5F3)
        : const Color(0xFF1E1E1E);
    final foreground = foregroundColor ?? fallback;
    final style = TextStyle(
      color: foreground,
      fontSize: fontSize,
      height: 1,
      fontWeight: FontWeight.w900,
      letterSpacing: -0.8,
    );

    return Semantics(
      label: 'Kaibigan',
      child: ExcludeSemantics(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text.rich(
            TextSpan(
              style: style,
              children: const [
                TextSpan(text: 'K'),
                TextSpan(
                  text: 'ai',
                  style: TextStyle(color: Color(0xFFE5A93C)),
                ),
                TextSpan(text: 'bigan'),
              ],
            ),
            maxLines: 1,
          ),
        ),
      ),
    );
  }
}
