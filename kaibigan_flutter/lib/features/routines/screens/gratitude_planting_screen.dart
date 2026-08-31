import 'package:flutter/material.dart';

import '../../gratitude_garden/garden_screen.dart';

/// Routine entry point for the canonical gratitude garden.
class GratitudePlantingScreen extends StatelessWidget {
  const GratitudePlantingScreen({
    super.key,
    this.onCompleted,
    this.onSkipped,
  });

  final VoidCallback? onCompleted;
  final VoidCallback? onSkipped;

  @override
  Widget build(BuildContext context) {
    return GardenScreen(
      openPlantingOnStart: true,
      onEntrySaved: onCompleted,
      onRoutineSkip: onSkipped,
    );
  }
}
