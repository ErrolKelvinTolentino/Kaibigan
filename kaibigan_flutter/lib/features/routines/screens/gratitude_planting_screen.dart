import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../gratitude_garden/gratitude_provider.dart';

class GratitudePlantingScreen extends StatefulWidget {
  const GratitudePlantingScreen({super.key});

  @override
  State<GratitudePlantingScreen> createState() => _GratitudePlantingScreenState();
}

class _GratitudePlantingScreenState extends State<GratitudePlantingScreen> {
  final TextEditingController _gratitudeController = TextEditingController();
  String _selectedFlowerType = 'sunflower';
  bool _isPlanted = false;

  final List<Map<String, String>> _flowerTypes = [
    {'type': 'sunflower', 'name': 'Sunflower', 'desc': 'Bright & uplifting'},
    {'type': 'sampaguita', 'name': 'Sampaguita', 'desc': 'Pure & fragrant'},
    {'type': 'tulip', 'name': 'Tulip', 'desc': 'Peaceful & gentle'},
    {'type': 'orchid', 'name': 'Orchid', 'desc': 'Resilient & calm'},
    {'type': 'rose', 'name': 'Rose', 'desc': 'Warm & loving'},
  ];

  @override
  void dispose() {
    _gratitudeController.dispose();
    super.dispose();
  }

  void _plantFlower() {
    if (_gratitudeController.text.trim().isEmpty) return;

    final gratitudeProvider = Provider.of<GratitudeProvider>(context, listen: false);
    gratitudeProvider.addGratitudeEntry(
      _gratitudeController.text.trim(),
      flowerType: _selectedFlowerType,
    );

    setState(() {
      _isPlanted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.warmCream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Plant Gratitude Flower',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _isPlanted ? _buildSuccessView(isDark) : _buildPlantingForm(isDark),
        ),
      ),
    );
  }

  Widget _buildPlantingForm(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: isDark ? AppColors.darkCardBorder : Colors.black.withValues(alpha: 0.06)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.sageGreen.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.local_florist_outlined, color: AppColors.sageGreen, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Gratitude Garden', style: AppTypography.bodySmall(context, isDark: isDark)),
                    Text('Plant a new memory', style: AppTypography.titleMedium(context, isDark: isDark)),
                  ],
                ),
              ),
            ],
          ),
        ).animate().fadeIn().slideY(begin: -0.05),
        const SizedBox(height: 24),

        Text(
          'What are you grateful for today?',
          style: AppTypography.titleMedium(context, isDark: isDark),
        ),
        const SizedBox(height: 6),
        Text(
          'Every grateful note plants a new blooming flower in your garden.',
          style: AppTypography.bodyMedium(context, isDark: isDark),
        ),
        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: isDark ? AppColors.darkCardBorder : Colors.black.withValues(alpha: 0.08)),
          ),
          child: TextField(
            controller: _gratitudeController,
            maxLines: 5,
            style: TextStyle(fontSize: 15, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
            decoration: const InputDecoration(
              hintText: 'I am deeply grateful for...',
              border: InputBorder.none,
            ),
          ),
        ),
        const SizedBox(height: 24),

        Text(
          'Choose Flower Variety:',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
        ),
        const SizedBox(height: 12),

        ..._flowerTypes.map((flower) {
          final isSelected = _selectedFlowerType == flower['type'];
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedFlowerType = flower['type']!;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.sageGreen.withValues(alpha: 0.15) : (isDark ? AppColors.darkCard : Colors.white),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppColors.sageGreen : (isDark ? AppColors.darkCardBorder : Colors.black.withValues(alpha: 0.06)),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.local_florist, color: isSelected ? AppColors.sageGreen : (isDark ? Colors.white54 : Colors.black45), size: 24),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(flower['name']!, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
                        Text(flower['desc']!, style: AppTypography.bodySmall(context, isDark: isDark)),
                      ],
                    ),
                  ),
                  if (isSelected) const Icon(Icons.check_circle, color: AppColors.sageGreen, size: 20),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 32),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _plantFlower,
            icon: const Icon(Icons.local_florist),
            label: const Text('Plant Flower in Garden', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.sageGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessView(bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 40),
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AppColors.sageGreen.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.local_florist, color: AppColors.sageGreen, size: 64),
        ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
        const SizedBox(height: 24),
        Text(
          'Flower Planted!',
          textAlign: TextAlign.center,
          style: AppTypography.titleLarge(context, isDark: isDark),
        ),
        const SizedBox(height: 12),
        Text(
          'Your gratitude entry has bloomed into a beautiful flower in your garden.',
          textAlign: TextAlign.center,
          style: AppTypography.bodyLarge(context, isDark: isDark),
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.sageGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              elevation: 0,
            ),
            child: const Text('Done', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }
}
