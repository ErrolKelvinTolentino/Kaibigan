import 'dart:ui' as ui;
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'gratitude_model.dart';

/// Renders the supplied transparent flower art so it blends gently into the
/// painted garden instead of reading as a hard-edged sprite.
class PolishedFlowerAsset extends StatelessWidget {
  const PolishedFlowerAsset({
    super.key,
    required this.flowerType,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.glowOpacity = 0.2,
    this.glowBlur = 8,
    this.cacheWidth,
    this.cacheHeight,
  });

  final String flowerType;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double glowOpacity;
  final double glowBlur;
  final int? cacheWidth;
  final int? cacheHeight;

  @override
  Widget build(BuildContext context) {
    final assetPath = GratitudeEntry.getFlowerAssetPath(flowerType);
    final glowColor = GratitudeEntry.getFlowerColor(flowerType);
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);
    final targetWidth = math.max(
      cacheWidth ?? 0,
      width == null ? 0 : (width! * pixelRatio * 1.5).ceil(),
    );
    final targetHeight = math.max(
      cacheHeight ?? 0,
      height == null ? 0 : (height! * pixelRatio * 1.5).ceil(),
    );
    final decodeScale = math.min(
      1.0,
      math.max(targetWidth / 1091, targetHeight / 2000),
    );
    final requestedWidth =
        decodeScale == 0 ? null : (1091 * decodeScale).ceil();
    final requestedHeight =
        decodeScale == 0 ? null : (2000 * decodeScale).ceil();

    Widget flowerImage({required FilterQuality quality}) => Image.asset(
          assetPath,
          fit: fit,
          filterQuality: quality,
          isAntiAlias: true,
          gaplessPlayback: true,
          excludeFromSemantics: true,
          cacheWidth: requestedWidth,
          cacheHeight: requestedHeight,
        );

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.none,
        children: [
          if (glowOpacity > 0)
            ImageFiltered(
              imageFilter: ui.ImageFilter.blur(
                sigmaX: glowBlur,
                sigmaY: glowBlur,
              ),
              child: Opacity(
                opacity: glowOpacity,
                child: ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    glowColor,
                    BlendMode.srcIn,
                  ),
                  child: flowerImage(quality: FilterQuality.high),
                ),
              ),
            ),
          flowerImage(quality: FilterQuality.high),
        ],
      ),
    );
  }
}
