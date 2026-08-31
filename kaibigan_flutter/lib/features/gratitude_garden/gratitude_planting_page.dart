import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/journal_paper_surface.dart';
import '../settings/user_provider.dart';
import 'gratitude_model.dart';
import 'gratitude_provider.dart';
import 'polished_flower_asset.dart';

enum _PlantingStage { reflection, flower }

enum GratitudePlantingOutcome { skipped }

class GratitudePlantingPage extends StatefulWidget {
  const GratitudePlantingPage({
    super.key,
    required this.gardenIndex,
    this.allowRoutineSkip = false,
    this.onSaved,
  });

  final int gardenIndex;
  final bool allowRoutineSkip;
  final VoidCallback? onSaved;

  @override
  State<GratitudePlantingPage> createState() => _GratitudePlantingPageState();
}

class _GratitudePlantingPageState extends State<GratitudePlantingPage> {
  static const _prompts = <({String label, String prompt})>[
    (
      label: 'A small comfort',
      prompt: 'What made today feel a little softer or easier?',
    ),
    (
      label: 'Someone',
      prompt: 'Who showed up for you, even in a small way?',
    ),
    (
      label: 'A moment',
      prompt: 'Which moment from today would you like to keep?',
    ),
    (
      label: 'Something in me',
      prompt: 'What did you appreciate about how you met today?',
    ),
  ];

  final _entryController = TextEditingController();
  final _entryFocus = FocusNode();
  late final PageController _flowerController;
  _PlantingStage _stage = _PlantingStage.reflection;
  int _promptIndex = 0;
  late int _flowerIndex;
  bool _isSaving = false;
  String? _validationMessage;

  @override
  void initState() {
    super.initState();
    _flowerIndex = 0;
    _flowerController = PageController(
      initialPage: _flowerIndex,
      viewportFraction: 0.78,
    );
  }

  @override
  void dispose() {
    _entryController.dispose();
    _entryFocus.dispose();
    _flowerController.dispose();
    super.dispose();
  }

  void _continueToFlower() {
    if (_entryController.text.trim().isEmpty) {
      setState(() {
        _validationMessage =
            'Write one honest thing you appreciate before continuing.';
      });
      _entryFocus.requestFocus();
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _validationMessage = null;
      _stage = _PlantingStage.flower;
    });
  }

  Future<void> _plant() async {
    if (_isSaving) return;
    setState(() {
      _isSaving = true;
      _validationMessage = null;
    });
    final provider = context.read<GratitudeProvider>();
    final entry = await provider.addGratitudeEntry(
      _entryController.text.trim(),
      flowerType: GratitudeEntry.availableFlowerTypes[_flowerIndex],
      gardenIndex: widget.gardenIndex,
    );
    if (!mounted) return;
    if (entry == null) {
      setState(() {
        _isSaving = false;
        _validationMessage = provider.errorMessage ??
            'This memory could not be planted. Please try again.';
      });
      return;
    }
    if (widget.onSaved != null) {
      widget.onSaved!();
    } else {
      Navigator.of(context).pop(entry);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final surface = isDark ? AppColors.darkCard : Colors.white;
    final pageColor = isDark ? AppColors.darkBackground : AppColors.warmCream;

    return PopScope(
      canPop: !_isSaving,
      child: Scaffold(
        key: const ValueKey('gratitude-planting-page'),
        backgroundColor: pageColor,
        appBar: AppBar(
          backgroundColor: pageColor,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            tooltip: 'Close',
            onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded),
          ),
          actions: [
            if (widget.allowRoutineSkip)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: TextButton.icon(
                  key: const ValueKey('skip-routine-activity'),
                  onPressed: _isSaving
                      ? null
                      : () => Navigator.of(context).pop(
                            GratitudePlantingOutcome.skipped,
                          ),
                  icon: const Icon(Icons.skip_next_rounded, size: 19),
                  label: const Text(
                    'Skip',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
          ],
          titleSpacing: 4,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _stage == _PlantingStage.reflection
                    ? 'A gratitude moment'
                    : 'Choose your flower',
                style: TextStyle(
                  color: primary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'Garden ${widget.gardenIndex + 1}  •  ${_stage == _PlantingStage.reflection ? 'Reflect' : 'Let it bloom'}',
                style: TextStyle(
                  color: secondary,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(5),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 4,
                    color: AppColors.honeyAmber,
                  ),
                ),
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 240),
                    height: 4,
                    color: _stage == _PlantingStage.flower
                        ? AppColors.honeyAmber
                        : (isDark ? Colors.white12 : const Color(0xFFE4E0D7)),
                  ),
                ),
              ],
            ),
          ),
        ),
        body: SafeArea(
          top: false,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.04, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: _stage == _PlantingStage.reflection
                ? _buildReflection(
                    isDark: isDark,
                    primary: primary,
                    secondary: secondary,
                    surface: surface,
                  )
                : _buildFlowerCarousel(
                    isDark: isDark,
                    primary: primary,
                    secondary: secondary,
                    surface: surface,
                  ),
          ),
        ),
        bottomNavigationBar: _buildBottomAction(
          isDark: isDark,
          primary: primary,
          surface: surface,
        ),
      ),
    );
  }

  Widget _buildReflection({
    required bool isDark,
    required Color primary,
    required Color secondary,
    required Color surface,
  }) {
    final paperStyle = context.watch<UserProvider>().journalPaperStyle;
    return ListView(
      key: const ValueKey('gratitude-reflection-step'),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 28),
      children: [
        Text(
          'Start with what feels true.',
          style: TextStyle(
            color: primary,
            fontSize: 27,
            height: 1.12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Gratitude does not need to be big or polished. One specific moment is enough.',
          style: TextStyle(color: secondary, fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 24),
        Text(
          'A gentle place to begin',
          style: TextStyle(
            color: primary,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _prompts.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final selected = index == _promptIndex;
              return ChoiceChip(
                key: ValueKey('gratitude-prompt-$index'),
                selected: selected,
                onSelected: (_) => setState(() => _promptIndex = index),
                showCheckmark: false,
                label: Text(_prompts[index].label),
                labelStyle: TextStyle(
                  color: selected ? Colors.white : primary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
                selectedColor: AppColors.honeyAmber,
                backgroundColor: surface,
                side: BorderSide(
                  color: selected
                      ? AppColors.honeyAmber
                      : isDark
                          ? AppColors.darkCardBorder
                          : const Color(0xFFE4E0D7),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: Container(
            key: ValueKey('prompt-copy-$_promptIndex'),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color:
                  AppColors.honeyAmber.withValues(alpha: isDark ? 0.16 : 0.1),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.honeyAmber.withValues(alpha: 0.22),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.eco_outlined,
                  color: AppColors.honeyAmber,
                  size: 19,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _prompts[_promptIndex].prompt,
                    style: TextStyle(
                      color: primary,
                      fontSize: 14,
                      height: 1.4,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        JournalPaperSurface(
          key: const ValueKey('gratitude-paper-note'),
          style: paperStyle,
          accentColor: AppColors.honeyAmber,
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 14),
          child: TextField(
            key: const ValueKey('gratitude-planting-field'),
            controller: _entryController,
            focusNode: _entryFocus,
            minLines: 7,
            maxLines: 10,
            maxLength: 600,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) {
              if (_validationMessage != null) {
                setState(() => _validationMessage = null);
              }
            },
            style: TextStyle(color: primary, fontSize: 16, height: 1.65),
            decoration: InputDecoration(
              hintText: 'Write the moment as you remember it…',
              errorText: _validationMessage,
              errorMaxLines: 2,
              errorStyle: const TextStyle(
                color: AppColors.honeyAmber,
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
              hintStyle: TextStyle(
                color: secondary.withValues(alpha: 0.68),
                fontStyle: FontStyle.italic,
              ),
              counterStyle: TextStyle(color: secondary, fontSize: 10.5),
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFlowerCarousel({
    required bool isDark,
    required Color primary,
    required Color secondary,
    required Color surface,
  }) {
    return LayoutBuilder(
      key: const ValueKey('gratitude-flower-step'),
      builder: (context, constraints) {
        final carouselHeight =
            (constraints.maxHeight * 0.66).clamp(390.0, 520.0);
        return ListView(
          padding: const EdgeInsets.fromLTRB(0, 20, 0, 28),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How should this memory bloom?',
                    style: TextStyle(
                      color: primary,
                      fontSize: 25,
                      height: 1.15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'Swipe through the garden flowers. Each one carries a different intention.',
                    style: TextStyle(
                      color: secondary,
                      fontSize: 13.5,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              key: const ValueKey('gratitude-flower-carousel'),
              height: carouselHeight,
              child: PageView.builder(
                controller: _flowerController,
                itemCount: GratitudeEntry.availableFlowerTypes.length,
                onPageChanged: (index) => setState(() => _flowerIndex = index),
                itemBuilder: (context, index) {
                  final type = GratitudeEntry.availableFlowerTypes[index];
                  return AnimatedBuilder(
                    animation: _flowerController,
                    builder: (context, child) {
                      var distance = 0.0;
                      if (_flowerController.hasClients &&
                          _flowerController.position.haveDimensions) {
                        distance = ((_flowerController.page ??
                                    _flowerController.initialPage) -
                                index)
                            .abs()
                            .clamp(0.0, 1.0)
                            .toDouble();
                      } else if (index != _flowerIndex) {
                        distance = 1.0;
                      }
                      final scale = 1 - (distance * 0.09);
                      return Transform.scale(scale: scale, child: child);
                    },
                    child: _FlowerCarouselCard(
                      type: type,
                      isDark: isDark,
                      primary: primary,
                      secondary: secondary,
                      surface: surface,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                GratitudeEntry.availableFlowerTypes.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: index == _flowerIndex ? 20 : 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: index == _flowerIndex
                        ? AppColors.honeyAmber
                        : secondary.withValues(alpha: 0.24),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 13, 16, 14),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkCardBorder
                        : const Color(0xFFE4E0D7),
                  ),
                ),
                child: Text(
                  '“${_entryController.text.trim()}”',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: secondary,
                    fontSize: 12.5,
                    height: 1.42,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
            if (_validationMessage != null) ...[
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: _InlineMessage(
                  message: _validationMessage!,
                  isDark: isDark,
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildBottomAction({
    required bool isDark,
    required Color primary,
    required Color surface,
  }) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
        decoration: BoxDecoration(
          color: surface,
          border: Border(
            top: BorderSide(
              color:
                  isDark ? AppColors.darkCardBorder : const Color(0xFFE8E3DA),
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
              blurRadius: 18,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: _stage == _PlantingStage.reflection
            ? SizedBox(
                height: 54,
                child: FilledButton.icon(
                  key: const ValueKey('continue-to-flower'),
                  onPressed: _continueToFlower,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text('Continue to your flower'),
                  style: _primaryButtonStyle(),
                ),
              )
            : Row(
                children: [
                  SizedBox(
                    width: 104,
                    height: 54,
                    child: OutlinedButton(
                      onPressed: _isSaving
                          ? null
                          : () => setState(
                                () => _stage = _PlantingStage.reflection,
                              ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primary,
                        side: BorderSide(
                          color: isDark
                              ? AppColors.darkCardBorder
                              : const Color(0xFFDCD6CC),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(17),
                        ),
                      ),
                      child: const Text('Back'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 54,
                      child: FilledButton.icon(
                        key: const ValueKey('confirm-plant-flower'),
                        onPressed: _isSaving ? null : _plant,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.eco_outlined),
                        label: Text(
                          _isSaving ? 'Planting…' : 'Plant this memory',
                        ),
                        style: _primaryButtonStyle(),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  ButtonStyle _primaryButtonStyle() => FilledButton.styleFrom(
        backgroundColor: AppColors.honeyAmber,
        foregroundColor: AppColors.onHoney,
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(17),
        ),
      );
}

class _FlowerCarouselCard extends StatelessWidget {
  const _FlowerCarouselCard({
    required this.type,
    required this.isDark,
    required this.primary,
    required this.secondary,
    required this.surface,
  });

  final String type;
  final bool isDark;
  final Color primary;
  final Color secondary;
  final Color surface;

  @override
  Widget build(BuildContext context) {
    final accent = GratitudeEntry.getFlowerColor(type);
    return Semantics(
      selected: true,
      label:
          '${GratitudeEntry.getFlowerName(type)}, ${GratitudeEntry.getFlowerMeaning(type)}',
      child: Container(
        key: ValueKey('flower-seed-$type'),
        margin: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
        padding: const EdgeInsets.fromLTRB(16, 15, 16, 18),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: accent.withValues(alpha: 0.6), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: isDark ? 0.1 : 0.14),
              blurRadius: 22,
              offset: const Offset(0, 9),
            ),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: isDark ? 0.12 : 0.08),
                  borderRadius: BorderRadius.circular(23),
                ),
                child: PolishedFlowerAsset(
                  flowerType: type,
                  glowOpacity: 0.18,
                  glowBlur: 10,
                  cacheWidth: 480,
                  cacheHeight: 880,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              GratitudeEntry.getFlowerName(type),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: primary,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              GratitudeEntry.getFlowerMeaning(type),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: secondary,
                fontSize: 12.5,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineMessage extends StatelessWidget {
  const _InlineMessage({required this.message, required this.isDark});

  final String message;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.honeyGold.withValues(alpha: isDark ? 0.2 : 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.honeyAmber.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.honeyAmber,
            size: 18,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
