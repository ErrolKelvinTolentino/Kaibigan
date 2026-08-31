import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../gratitude_garden/garden_layout.dart';
import '../../gratitude_garden/gratitude_planting_page.dart';
import '../../gratitude_garden/gratitude_provider.dart';

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
    final provider = context.watch<GratitudeProvider>();
    final gardenIndex = GardenLayout.automaticPlantingGarden(provider.entries);
    return GratitudePlantingPage(
      gardenIndex: gardenIndex,
      onSaved: onCompleted,
    );
  }
}
