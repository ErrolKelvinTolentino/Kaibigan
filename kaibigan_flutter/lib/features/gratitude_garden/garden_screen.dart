import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/widgets/cozy_confirm_sheet.dart';
import '../settings/user_provider.dart';
import 'gratitude_provider.dart';
import 'gratitude_model.dart';

class GardenScreen extends StatefulWidget {
  const GardenScreen({super.key});

  @override
  State<GardenScreen> createState() => _GardenScreenState();
}

class _GardenScreenState extends State<GardenScreen> {
  final TextEditingController _entryController = TextEditingController();
  String _selectedFlowerType = 'sunflower';
  bool _isListView = false;

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gardenProvider = Provider.of<GratitudeProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Gratitude Garden',
          style: AppTypography.titleLarge(context, isDark: isDark),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isListView ? Icons.yard_outlined : Icons.format_list_bulleted_rounded,
              color: AppColors.sageGreen,
            ),
            tooltip: _isListView ? 'View Garden Bed' : 'View Flower List',
            onPressed: () {
              setState(() {
                _isListView = !_isListView;
              });
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.music_note_outlined, color: AppColors.sageGreen),
            tooltip: 'Ambient Soundscapes',
            onSelected: (val) {
              gardenProvider.setSoundscape(val);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('🎵 Soundscape set to: ${val.replaceAll('_', ' ')}')),
              );
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'lofi_guitar', child: Text('🎸 Lo-fi Acoustic Guitar')),
              const PopupMenuItem(value: 'rain_nipa', child: Text('🌧️ Rain on Nipa Roof')),
              const PopupMenuItem(value: 'night_crickets', child: Text('🦗 Tropical Night Crickets')),
              const PopupMenuItem(value: 'ocean_breeze', child: Text('🌊 Batanes Ocean Breeze')),
              const PopupMenuItem(value: 'off', child: Text('🔇 Soundscape Off')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.groups_outlined, color: AppColors.sageGreen),
            tooltip: 'Bayanihan Community Meadow',
            onPressed: () => _showBayanihanMeadowSheet(context, gardenProvider),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Level Progress & Stats Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    // Level Badge & Progress
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.sageGreen.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                '🌱 Level ${gardenProvider.gardenLevel}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.sageGreen,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${gardenProvider.flowersInCurrentLevel}/5 to Next Level',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${(gardenProvider.levelProgress * 100).toInt()}%',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.sageGreen,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Progress Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: gardenProvider.levelProgress == 0 ? 0.05 : gardenProvider.levelProgress,
                        minHeight: 8,
                        backgroundColor: isDark ? Colors.white12 : const Color(0xFFE5EFE7),
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.sageGreen),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Stats Badges Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatBadge('🌻', '${gardenProvider.flowerCount} Flowers', isDark),
                        _buildStatBadge('💧', '${gardenProvider.waterDrops} Drops', isDark),
                        _buildStatBadge('🦋', gardenProvider.hasButterflies ? 'Unlocked' : 'At 3 🌻', isDark),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Main View Area: Either Garden Bed Canvas OR Flower List View
            Expanded(
              child: _isListView
                  ? _buildGardenListView(context, gardenProvider, isDark, userProvider)
                  : Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(32),
                        gradient: LinearGradient(
                          colors: isDark
                              ? [const Color(0xFF1B2A20), const Color(0xFF111A14)]
                              : [const Color(0xFFEBF6EC), const Color(0xFFCBEAD0)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          )
                        ],
                      ),
                      child: Stack(
                        children: [
                          // Dynamic Sky Elements
                          // Golden Sun
                          Positioned(
                            top: 18,
                            right: 20,
                            child: Container(
                              width: 52,
                              height: 52,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFFFFF176),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0xFFFFEE58),
                                    blurRadius: 22,
                                    spreadRadius: 6,
                                  )
                                ],
                              ),
                            ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                             .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 3000.ms),
                          ),

                          // Floating Clouds
                          Positioned(
                            top: 25,
                            left: 24,
                            child: const Text('☁️', style: TextStyle(fontSize: 30))
                                .animate(onPlay: (controller) => controller.repeat(reverse: true))
                                .moveX(begin: 0, end: 15, duration: 4000.ms),
                          ),

                          // Rainbow (Unlocked at 10 flowers)
                          if (gardenProvider.hasRainbow)
                            Positioned(
                              top: 10,
                              left: 60,
                              child: const Text('🌈', style: TextStyle(fontSize: 48))
                                  .animate(onPlay: (controller) => controller.repeat(reverse: true))
                                  .scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05), duration: 3500.ms),
                            ),

                          // Butterflies (Unlocked at 3 flowers)
                          if (gardenProvider.hasButterflies) ...[
                            Positioned(
                              top: 80,
                              right: 80,
                              child: const Text('🦋', style: TextStyle(fontSize: 22))
                                  .animate(onPlay: (controller) => controller.repeat(reverse: true))
                                  .moveY(begin: 0, end: -12, duration: 1800.ms),
                            ),
                            Positioned(
                              top: 120,
                              left: 40,
                              child: const Text('🦋', style: TextStyle(fontSize: 18))
                                  .animate(onPlay: (controller) => controller.repeat(reverse: true))
                                  .moveY(begin: 0, end: -10, duration: 2200.ms),
                            ),
                          ],

                          // Rolling Grass Hill at Bottom
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            height: 110,
                            child: Container(
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1F3A26) : const Color(0xFF7BA273),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(90),
                                  topRight: Radius.circular(90),
                                  bottomLeft: Radius.circular(32),
                                  bottomRight: Radius.circular(32),
                                ),
                              ),
                            ),
                          ),

                          // Blooming Flowers Grid in Garden Plot Bed
                          Positioned.fill(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 70, bottom: 20, left: 16, right: 16),
                              child: gardenProvider.entries.isEmpty
                                  ? Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Text('🌱', style: TextStyle(fontSize: 48)),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Plant your first gratitude flower!',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: isDark ? Colors.white70 : const Color(0xFF2C2C2C),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : GridView.builder(
                                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 3,
                                        crossAxisSpacing: 14,
                                        mainAxisSpacing: 18,
                                      ),
                                      itemCount: gardenProvider.entries.length,
                                      itemBuilder: (context, index) {
                                        final entry = gardenProvider.entries[index];
                                        return GestureDetector(
                                          onTap: () => _showFlowerDetailSheet(context, entry, userProvider.preferredLanguage),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: [
                                              // Flower Icon with sway animation
                                              Icon(
                                                GratitudeEntry.getFlowerMaterialIcon(entry.flowerType),
                                                color: GratitudeEntry.getFlowerColor(entry.flowerType),
                                                size: 42,
                                              ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                                               .scale(begin: const Offset(1, 1), end: const Offset(1.08, 1.08), duration: 2200.ms),
                                              // Soil mound base
                                              Container(
                                                width: 24,
                                                height: 8,
                                                decoration: BoxDecoration(
                                                  color: isDark ? const Color(0xFF382315) : const Color(0xFF5D4037),
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: 14),

            // Bottom "+ Plant a Gratitude Flower" Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF9326), // Quabble Orange Accent
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
                  label: const Text(
                    'Plant a Gratitude Flower',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  onPressed: () => _showPlantingCeremonySheet(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBadge(String emoji, String text, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? Colors.black26 : const Color(0xFFF6F4ED),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textPrimaryDark : const Color(0xFF2C2C2C),
            ),
          ),
        ],
      ),
    );
  }

  // Interactive Seed Selection & Planting Ceremony Modal Sheet
  void _showPlantingCeremonySheet(BuildContext context) {
    _selectedFlowerType = 'sunflower';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.local_florist_rounded, color: AppColors.sageGreen, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'Plant a Gratitude Flower',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF2C2C2C)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Pick a flower seed and write what brought warmth to your heart today.',
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  const SizedBox(height: 18),

                  // Step 1: Choose Your Flower Seed
                  const Text(
                    'Choose Flower Seed:',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF2C2C2C)),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSeedChoice('sunflower', '🌻', 'Sunflower', setModalState),
                      _buildSeedChoice('sampaguita', '🌼', 'Sampaguita', setModalState),
                      _buildSeedChoice('tulip', '🌷', 'Tulip', setModalState),
                      _buildSeedChoice('orchid', '🪻', 'Orchid', setModalState),
                      _buildSeedChoice('rose', '🌹', 'Rose', setModalState),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Step 2: Gratitude Text Input
                  const Text(
                    'What are you grateful for today?',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF2C2C2C)),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _entryController,
                    maxLines: 3,
                    style: const TextStyle(fontSize: 15, color: Color(0xFF2C2C2C)),
                    decoration: InputDecoration(
                      hintText: 'Isulat mo lang rito ang nakapagpasaya sa iyo...',
                      filled: true,
                      fillColor: const Color(0xFFF6F4ED),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Step 3: Plant Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.sageGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.water_drop_rounded, color: Colors.white),
                      label: const Text(
                        'Plant Seed (+10 💧)',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                      onPressed: () {
                        if (_entryController.text.trim().isEmpty) return;
                        final provider = Provider.of<GratitudeProvider>(context, listen: false);
                        provider.addGratitudeEntry(
                          _entryController.text.trim(),
                          flowerType: _selectedFlowerType,
                          shareToCommunity: true,
                        );
                        _entryController.clear();
                        Navigator.pop(context);

                        // Celebratory Feedback
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '🎉 A new ${GratitudeEntry.getFlowerName(_selectedFlowerType)} bloomed in your garden! (+10 💧)',
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            backgroundColor: AppColors.sageGreen,
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSeedChoice(String type, String icon, String name, StateSetter setModalState) {
    final isSelected = _selectedFlowerType == type;
    return GestureDetector(
      onTap: () {
        setModalState(() {
          _selectedFlowerType = type;
        });
      },
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.sageGreen.withValues(alpha: 0.2) : const Color(0xFFF6F4ED),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? AppColors.sageGreen : Colors.transparent,
                width: 2.0,
              ),
            ),
            child: Center(
              child: Icon(
                GratitudeEntry.getFlowerMaterialIcon(type),
                color: isSelected ? AppColors.sageGreen : const Color(0xFF5E5B52),
                size: 26,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            name,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? AppColors.sageGreen : const Color(0xFF2C2C2C),
            ),
          ),
        ],
      ),
    );
  }

  // Storybook Flower Memory Card Sheet
  void _showFlowerDetailSheet(BuildContext context, GratitudeEntry entry, String language) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) {
        final provider = Provider.of<GratitudeProvider>(context);

        return Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                GratitudeEntry.getFlowerMaterialIcon(entry.flowerType),
                color: GratitudeEntry.getFlowerColor(entry.flowerType),
                size: 64,
              ).animate().scale(duration: 300.ms, curve: Curves.easeOut),
              const SizedBox(height: 8),
              Text(
                '${GratitudeEntry.getFlowerName(entry.flowerType)} • ${GratitudeEntry.getFlowerMeaning(entry.flowerType)}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.sageGreen),
              ),
              const SizedBox(height: 6),
              Text(
                DateFormatter.formatFullDate(entry.createdAt, language: language),
                style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F4ED),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '"${entry.content}"',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C2C2C),
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Watering, Edit & Delete Action Buttons
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.sageGreen,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.water_drop_rounded, color: Colors.white, size: 18),
                        label: Text(
                          'Water (${entry.waterCount}x 💧)',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                        onPressed: () {
                          provider.waterFlower(entry.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('💧 You nourished this gratitude flower! (+3 💧 Drops)'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: AppColors.honeyAmber),
                    tooltip: 'Edit Gratitude',
                    onPressed: () {
                      Navigator.pop(context);
                      _showEditGratitudeDialog(context, entry, provider);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    tooltip: 'Let Go of Flower',
                    onPressed: () async {
                      final confirmed = await CozyConfirmSheet.show(
                        context,
                        title: 'Palayain ang Bulaklak?',
                        message: 'Ang pasasalamat na ito ay mananatili pa rin sa iyong puso. Nais mo bang alisin ang bulaklak na ito mula sa iyong hardin?',
                        confirmLabel: 'Let Go',
                        cancelLabel: 'Keep Flower',
                        icon: Icons.local_florist_rounded,
                      );
                      if (confirmed && context.mounted) {
                        provider.deleteGratitudeEntry(entry.id);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Flower gently removed from your garden.'),
                            behavior: SnackBarBehavior.floating,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditGratitudeDialog(BuildContext context, GratitudeEntry entry, GratitudeProvider provider) {
    final editController = TextEditingController(text: entry.content);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Icon(GratitudeEntry.getFlowerMaterialIcon(entry.flowerType), color: GratitudeEntry.getFlowerColor(entry.flowerType)),
            const SizedBox(width: 8),
            const Text('Edit Gratitude Note', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          ],
        ),
        content: TextField(
          controller: editController,
          maxLines: 3,
          style: TextStyle(fontSize: 14, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
          decoration: InputDecoration(
            hintText: 'Update your gratitude reflection...',
            filled: true,
            fillColor: isDark ? Colors.black26 : const Color(0xFFF6F4ED),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.sageGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () {
              if (editController.text.trim().isNotEmpty) {
                provider.updateGratitudeEntry(entry.id, editController.text.trim());
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Gratitude note updated! ✨'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showBayanihanMeadowSheet(BuildContext context, GratitudeProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkCard : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) {
        final communityItems = provider.communityEntries;
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.groups_rounded, color: AppColors.sageGreen, size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Bayanihan Community Meadow', style: AppTypography.titleMedium(context, isDark: isDark)),
                        const SizedBox(height: 2),
                        Text(
                          'Anonymous gratitude drops shared by fellow Filipinos.',
                          style: TextStyle(fontSize: 12, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (communityItems.isEmpty)
                const Center(child: Text('No community flowers yet. Plant one to share!'))
              else
                SizedBox(
                  height: 240,
                  child: ListView.builder(
                    itemCount: communityItems.length,
                    itemBuilder: (ctx, index) {
                      final item = communityItems[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCardBorder : const Color(0xFFF6F4ED),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              GratitudeEntry.getFlowerMaterialIcon(item.flowerType),
                              color: GratitudeEntry.getFlowerColor(item.flowerType),
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '"${item.content}"',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, height: 1.3),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              children: [
                                const Icon(Icons.water_drop, color: Colors.blueAccent, size: 16),
                                Text('${item.waterCount}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGardenListView(BuildContext context, GratitudeProvider provider, bool isDark, UserProvider userProvider) {
    if (provider.entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.local_florist_outlined, size: 48, color: AppColors.sageGreen),
              const SizedBox(height: 12),
              Text(
                'No flowers in your garden yet.',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Tap the button below to plant your first gratitude note.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      itemCount: provider.entries.length,
      itemBuilder: (context, index) {
        final entry = provider.entries[index];
        final flowerColor = GratitudeEntry.getFlowerColor(entry.flowerType);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? AppColors.darkCardBorder : Colors.black.withValues(alpha: 0.05),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            onTap: () => _showFlowerDetailSheet(context, entry, userProvider.preferredLanguage),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: flowerColor.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(
                GratitudeEntry.getFlowerMaterialIcon(entry.flowerType),
                color: flowerColor,
                size: 26,
              ),
            ),
            title: Text(
              '"${entry.content}"',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  Text(
                    GratitudeEntry.getFlowerName(entry.flowerType),
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: flowerColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '•  ${entry.waterCount}💧',
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Colors.blueAccent),
                  ),
                  const Spacer(),
                  Text(
                    DateFormatter.formatShortDate(entry.createdAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                ],
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.water_drop_rounded, color: Colors.blueAccent, size: 20),
              tooltip: 'Water Flower',
              onPressed: () {
                provider.waterFlower(entry.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('💧 Watered flower (+3 💧 Drops)!'),
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 1),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
