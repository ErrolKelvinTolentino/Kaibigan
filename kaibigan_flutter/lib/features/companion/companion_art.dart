import 'package:flutter/material.dart';

import 'companion_model.dart';

enum CompanionPose { welcoming, listening, celebrating }

/// The finalized Kai and Ann artwork, with an optional face crop for replies.
class CompanionArt extends StatelessWidget {
  const CompanionArt({
    super.key,
    required this.mascot,
    this.pose = CompanionPose.welcoming,
    this.size = 88,
    this.portrait = false,
  });

  final MascotInfo mascot;
  final CompanionPose pose;
  final double size;
  final bool portrait;

  @override
  Widget build(BuildContext context) {
    final asset = 'assets/mascots/${mascot.id}-${pose.name}.png';
    final art = Image.asset(
      asset,
      key: ValueKey('companion-art-${mascot.id}-${pose.name}'),
      fit: BoxFit.contain,
      excludeFromSemantics: true,
      cacheWidth:
          (size * MediaQuery.devicePixelRatioOf(context) * (portrait ? 3 : 1))
              .ceil()
              .clamp(1, 1254),
      errorBuilder: (_, __, ___) => Icon(mascot.materialIcon,
          size: size * 0.45, color: mascot.primaryColor),
    );
    return Semantics(
      image: true,
      label: '${mascot.name} bee mascot',
      child: SizedBox.square(
        dimension: size,
        child: portrait
            ? DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: mascot.primaryColor.withValues(alpha: 0.1),
                ),
                child: ClipOval(
                  child: Transform.scale(
                    scale: 2.65,
                    alignment: const Alignment(0.1, -0.65),
                    child: art,
                  ),
                ),
              )
            : art,
      ),
    );
  }
}
