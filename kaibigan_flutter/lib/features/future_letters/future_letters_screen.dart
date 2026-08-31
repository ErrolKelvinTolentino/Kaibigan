import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/widgets/cozy_confirm_sheet.dart';
import '../../core/widgets/mobile_layout.dart';
import '../../core/widgets/sync_status_banner.dart';
import 'letters_provider.dart';

const _ink = Color(0xFF2C2C2C);
const _sage = AppColors.sageGreen;
const _paper = Color(0xFFFFFAF1);
const _mist = Color(0xFFF7ECD9);
const _letterArtwork = 'assets/feature icons/Entries.png';

class FutureLettersScreen extends StatelessWidget {
  const FutureLettersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<LettersProvider>();
    final readyCount =
        provider.letters.where((letter) => letter.isReadyToUnlock).length;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.warmCream,
      body: SafeArea(
        child: RefreshIndicator(
          color: _sage,
          onRefresh: provider.fetchLetters,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(12, 8, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: 'Back',
                        onPressed: () => Navigator.maybePop(context),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      const Spacer(),
                      if (provider.letters.isNotEmpty)
                        _CountPill(
                          count: provider.letters.length,
                          isDark: isDark,
                        ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
                sliver: SliverToBoxAdapter(
                  child: _LibraryHeader(
                    isDark: isDark,
                    readyCount: readyCount,
                    onWrite: () => _openComposer(context),
                  ),
                ),
              ),
              if (provider.isLoading)
                const SliverToBoxAdapter(
                  child: LinearProgressIndicator(minHeight: 2, color: _sage),
                ),
              if (provider.errorMessage != null)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  sliver: SliverToBoxAdapter(
                    child: SyncStatusBanner(
                      message: provider.errorMessage!,
                      onRetry: provider.fetchLetters,
                    ),
                  ),
                ),
              if (provider.letters.isEmpty && !provider.isLoading)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyLibrary(
                    isDark: isDark,
                    onWrite: () => _openComposer(context),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
                  sliver: SliverList.separated(
                    itemCount: provider.letters.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final letter = provider.letters[index];
                      return _LetterCard(
                        letter: letter,
                        isDark: isDark,
                        onOpen: () => _openLetter(context, letter),
                        onDelete: () => _deleteLetter(context, letter),
                      )
                          .animate(delay: (45 * index).ms)
                          .fadeIn(duration: 280.ms)
                          .slideY(begin: 0.04, curve: Curves.easeOutCubic);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _openComposer(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 420),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, animation, __) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: const _LetterComposer(),
        ),
        transitionsBuilder: (_, animation, __, child) => SlideTransition(
          position: Tween(begin: const Offset(0, 0.035), end: Offset.zero)
              .animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: child,
        ),
      ),
    );
  }

  void _openLetter(BuildContext context, FutureLetter letter) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _LetterReader(letter: letter),
      ),
    );
  }

  Future<void> _deleteLetter(
    BuildContext context,
    FutureLetter letter,
  ) async {
    final confirmed = await CozyConfirmSheet.show(
      context,
      title: 'Let this letter go?',
      message:
          '“${letter.title}” will leave your shelf. This cannot be undone.',
      confirmLabel: 'Remove',
      cancelLabel: 'Keep it',
      icon: Icons.mail_outline_rounded,
    );
    if (!confirmed || !context.mounted) return;

    final provider = context.read<LettersProvider>();
    final deleted = await provider.deleteLetter(letter.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          deleted
              ? 'Letter removed.'
              : provider.errorMessage ?? 'The letter could not be removed.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _LibraryHeader extends StatelessWidget {
  final bool isDark;
  final int readyCount;
  final VoidCallback onWrite;

  const _LibraryHeader({
    required this.isDark,
    required this.readyCount,
    required this.onWrite,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: SizedBox(
            key: const ValueKey('future-letters-banner'),
            width: double.infinity,
            height: 178,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  _letterArtwork,
                  fit: BoxFit.cover,
                  alignment: const Alignment(0, -0.46),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.transparent,
                        const Color(0xFF593A22).withValues(alpha: 0.03),
                        const Color(0xFF4B2E1D).withValues(alpha: 0.48),
                      ],
                      stops: const [0.42, 0.62, 1],
                    ),
                  ),
                ),
                const Positioned(
                  right: 18,
                  bottom: 18,
                  width: 145,
                  child: Text(
                    'A little mail\nfor much later.',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      height: 1.15,
                      fontWeight: FontWeight.w800,
                      shadows: [Shadow(color: Colors.black26, blurRadius: 8)],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        Text(
          'Letters for later',
          style: TextStyle(
            color: AppColors.honeyAmber,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.15,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'A quiet inbox from you.',
          style: AppTypography.heroHeader(
            context,
            isDark: isDark,
            color: isDark ? AppColors.textPrimaryDark : _ink,
          ).copyWith(fontSize: 31, height: 1.1, letterSpacing: -0.8),
        ),
        const SizedBox(height: 12),
        Text(
          readyCount > 0
              ? '$readyCount ${readyCount == 1 ? 'letter has' : 'letters have'} arrived. Past you had something to say.'
              : 'Send a thought forward. Time will handle the delivery.',
          style: AppTypography.bodyMedium(context, isDark: isDark).copyWith(
            height: 1.55,
          ),
        ),
        const SizedBox(height: 22),
        SizedBox(
          height: 50,
          child: FilledButton.icon(
            key: const ValueKey('write-letter-button'),
            onPressed: onWrite,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.honeyAmber,
              foregroundColor: AppColors.onHoney,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(17),
              ),
            ),
            icon: const Icon(Icons.edit_note_rounded, size: 21),
            label: const Text(
              'Write a letter',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 350.ms).slideY(begin: -0.025);
  }
}

class _CountPill extends StatelessWidget {
  final int count;
  final bool isDark;

  const _CountPill({required this.count, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : _mist,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        '$count saved',
        style: TextStyle(
          color: isDark ? AppColors.textSecondaryDark : _sage,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _EmptyLibrary extends StatelessWidget {
  final bool isDark;
  final VoidCallback onWrite;

  const _EmptyLibrary({required this.isDark, required this.onWrite});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : _mist,
              borderRadius: BorderRadius.circular(25),
            ),
            child: Icon(
              Icons.markunread_mailbox_outlined,
              color: isDark ? AppColors.softOlive : _sage,
              size: 32,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Your future inbox is admirably tidy.',
            textAlign: TextAlign.center,
            style: AppTypography.titleSmall(context, isDark: isDark),
          ),
          const SizedBox(height: 7),
          Text(
            'Leave it a note worth waiting for.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium(context, isDark: isDark),
          ),
          const SizedBox(height: 18),
          TextButton(
            onPressed: onWrite,
            child: const Text('Start the first one'),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 140.ms, duration: 350.ms);
  }
}

class _LetterCard extends StatelessWidget {
  final FutureLetter letter;
  final bool isDark;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  const _LetterCard({
    required this.letter,
    required this.isDark,
    required this.onOpen,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final ready = letter.isReadyToUnlock;
    final accent = ready ? _sage : const Color(0xFF8B8173);
    final status = ready
        ? (letter.isOpened ? 'Read' : 'Arrived')
        : 'Delivers ${DateFormatter.formatShortDate(letter.deliverAt)}';

    return Material(
      color: isDark ? AppColors.darkCard : Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 10, 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color:
                  isDark ? AppColors.darkCardBorder : const Color(0xFFE9E3DA),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: isDark ? 0.18 : 0.11),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  ready
                      ? Icons.mail_outline_rounded
                      : Icons.lock_clock_outlined,
                  color: accent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      status,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: accent,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      letter.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleSmall(context, isDark: isDark),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      ready
                          ? 'Tap to ${letter.isOpened ? 'read again' : 'open'}'
                          : 'Sealed ${DateFormatter.formatShortDate(letter.createdAt)}',
                      style: AppTypography.bodySmall(context, isDark: isDark),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Delete letter',
                onPressed: onDelete,
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
              const Icon(Icons.chevron_right_rounded, size: 19),
            ],
          ),
        ),
      ),
    );
  }
}

class _LetterComposer extends StatefulWidget {
  const _LetterComposer();

  @override
  State<_LetterComposer> createState() => _LetterComposerState();
}

class _LetterComposerState extends State<_LetterComposer> {
  final _pages = PageController();
  final _title = TextEditingController();
  final _message = TextEditingController();
  int _page = 0;
  int _durationDays = 30;
  DateTime? _customDate;
  bool _saving = false;
  String? _validation;

  DateTime get _deliveryDate =>
      _customDate ?? DateTime.now().add(Duration(days: _durationDays));

  @override
  void dispose() {
    _pages.dispose();
    _title.dispose();
    _message.dispose();
    super.dispose();
  }

  void _back() {
    FocusScope.of(context).unfocus();
    if (_page == 0) {
      Navigator.pop(context);
      return;
    }
    _pages.previousPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  void _next() {
    FocusScope.of(context).unfocus();
    String? error;
    if (_page == 0 && _title.text.trim().isEmpty) {
      error = 'Give this letter a small signpost.';
    } else if (_page == 1 && _message.text.trim().isEmpty) {
      error = 'Future you deserves at least one sentence.';
    }
    if (error != null) {
      setState(() => _validation = error);
      return;
    }
    setState(() => _validation = null);
    _pages.nextPage(
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final provider = context.read<LettersProvider>();
    final saved = await provider.createLetter(
      title: _title.text.trim(),
      content: _message.text.trim(),
      deliverAt: _deliveryDate,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (saved != null) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Letter sealed. We will keep the suspense.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(provider.errorMessage ?? 'The letter could not be saved.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.warmCream,
      body: SafeArea(
        child: Column(
          children: [
            _ComposerHeader(page: _page, isDark: isDark, onClose: _back),
            Expanded(
              child: PageView(
                key: const ValueKey('letter-composer-pages'),
                controller: _pages,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (value) => setState(() {
                  _page = value;
                  _validation = null;
                }),
                children: [
                  _PurposePage(controller: _title, isDark: isDark),
                  _MessagePage(controller: _message, isDark: isDark),
                  _SchedulePage(
                    isDark: isDark,
                    durationDays: _durationDays,
                    usesCustomDate: _customDate != null,
                    deliveryDate: _deliveryDate,
                    onDurationChanged: (days) => setState(() {
                      _durationDays = days;
                      _customDate = null;
                    }),
                    onCustomDate: () => _pickDate(context),
                  ),
                  _ReviewPage(
                    isDark: isDark,
                    title: _title.text.trim(),
                    message: _message.text.trim(),
                    deliveryDate: _deliveryDate,
                  ),
                ],
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: _validation == null
                  ? const SizedBox(height: 0)
                  : Padding(
                      key: ValueKey(_validation),
                      padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
                      child: Text(
                        _validation!,
                        style: const TextStyle(
                          color: AppColors.softRose,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
            ),
            _ComposerActions(
              page: _page,
              saving: _saving,
              isDark: isDark,
              onBack: _back,
              onNext: _page == 3 ? _save : _next,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final chosen = await showDatePicker(
      context: context,
      initialDate: _deliveryDate,
      firstDate: now.add(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 3650)),
      helpText: 'WHEN SHOULD THIS ARRIVE?',
    );
    if (chosen != null) setState(() => _customDate = chosen);
  }
}

class _ComposerHeader extends StatelessWidget {
  final int page;
  final bool isDark;
  final VoidCallback onClose;

  const _ComposerHeader({
    required this.page,
    required this.isDark,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 18, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: onClose,
            tooltip: page == 0 ? 'Close' : 'Back',
            icon: Icon(
                page == 0 ? Icons.close_rounded : Icons.arrow_back_rounded),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Row(
              children: List.generate(4, (index) {
                return Expanded(
                  child: AnimatedContainer(
                    key: ValueKey('composer-progress-$index'),
                    duration: const Duration(milliseconds: 240),
                    height: 3,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: index <= page
                          ? AppColors.honeyAmber
                          : (isDark ? Colors.white12 : const Color(0xFFE2DDD4)),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(width: 14),
          Text(
            '${page + 1} / 4',
            style: AppTypography.bodySmall(context, isDark: isDark),
          ),
        ],
      ),
    );
  }
}

class _PageFrame extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;
  final bool isDark;
  final Widget child;

  const _PageFrame({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.isDark,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        MobileLayout.horizontalPadding(context),
        24,
        MobileLayout.horizontalPadding(context),
        24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            eyebrow,
            style: TextStyle(
              color: AppColors.honeyAmber,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            title,
            style: AppTypography.titleLarge(context, isDark: isDark)
                .copyWith(fontSize: 30, letterSpacing: -0.7),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: AppTypography.bodyMedium(context, isDark: isDark)
                .copyWith(height: 1.5),
          ),
          const SizedBox(height: 30),
          child,
        ],
      ),
    );
  }
}

class _PurposePage extends StatelessWidget {
  final TextEditingController controller;
  final bool isDark;

  const _PurposePage({required this.controller, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return _PageFrame(
      eyebrow: 'FIRST, A SIGNPOST',
      title: 'What is this letter for?',
      subtitle: 'A title is enough. The honest part gets its own page.',
      isDark: isDark,
      child: TextField(
        key: const ValueKey('letter-title-field'),
        controller: controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        textInputAction: TextInputAction.done,
        style: AppTypography.titleMedium(context, isDark: isDark),
        decoration: _fieldDecoration(
          isDark: isDark,
          hint: 'For the day I need courage',
          icon: Icons.title_rounded,
        ),
      ),
    );
  }
}

class _MessagePage extends StatefulWidget {
  final TextEditingController controller;
  final bool isDark;

  const _MessagePage({required this.controller, required this.isDark});

  @override
  State<_MessagePage> createState() => _MessagePageState();
}

class _MessagePageState extends State<_MessagePage> {
  static const _starters = [
    'Remember this:',
    'I hope you know',
    'A promise I am making',
    'When this feels difficult',
  ];

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() => setState(() {});

  void _useStarter(String starter) {
    if (widget.controller.text.trim().isNotEmpty) return;
    widget.controller.text = '$starter ';
    widget.controller.selection = TextSelection.collapsed(
      offset: widget.controller.text.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    return _PageFrame(
      eyebrow: 'NOW, THE LETTER',
      title: 'Write the part worth keeping.',
      subtitle:
          'No perfect words needed. Just something true enough to travel.',
      isDark: widget.isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Need a way in?',
            style: TextStyle(
              color: widget.isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 9),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _starters.map((starter) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    avatar: const Icon(
                      Icons.auto_awesome_outlined,
                      size: 15,
                      color: AppColors.honeyAmber,
                    ),
                    label: Text(starter),
                    onPressed: () => _useStarter(starter),
                    backgroundColor: widget.isDark
                        ? AppColors.darkCard
                        : AppColors.honeyLight,
                    side: BorderSide(
                      color: AppColors.honeyAmber.withValues(alpha: 0.24),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: widget.isDark ? AppColors.darkCard : _paper,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: widget.isDark
                    ? AppColors.darkCardBorder
                    : const Color(0xFFE9D8BD),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.honeyAmber.withValues(alpha: 0.06),
                  blurRadius: 22,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 15, 18, 0),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.mail_outline_rounded,
                        size: 18,
                        color: AppColors.honeyAmber,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'To my future self',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: widget.isDark
                                ? AppColors.textSecondaryDark
                                : _sage,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Semantics(
                        label:
                            '${widget.controller.text.trim().length} characters',
                        child: Text(
                          '${widget.controller.text.trim().length}',
                          style: AppTypography.bodySmall(
                            context,
                            isDark: widget.isDark,
                          ).copyWith(fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(
                  height: 25,
                  color: AppColors.honeyAmber.withValues(alpha: 0.18),
                ),
                TextField(
                  key: const ValueKey('letter-message-field'),
                  controller: widget.controller,
                  autofocus: true,
                  minLines: 10,
                  maxLines: 14,
                  textCapitalization: TextCapitalization.sentences,
                  style: AppTypography.bodyLarge(
                    context,
                    isDark: widget.isDark,
                  ).copyWith(height: 1.7),
                  decoration: InputDecoration(
                    hintText: 'Dear future me,',
                    hintStyle: TextStyle(
                      color: widget.isDark
                          ? AppColors.textSecondaryDark
                          : const Color(0xFFA49A8A),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SchedulePage extends StatelessWidget {
  final bool isDark;
  final int durationDays;
  final bool usesCustomDate;
  final DateTime deliveryDate;
  final ValueChanged<int> onDurationChanged;
  final VoidCallback onCustomDate;

  const _SchedulePage({
    required this.isDark,
    required this.durationDays,
    required this.usesCustomDate,
    required this.deliveryDate,
    required this.onDurationChanged,
    required this.onCustomDate,
  });

  @override
  Widget build(BuildContext context) {
    return _PageFrame(
      eyebrow: 'CHOOSE THE WAIT',
      title: 'When should it find you?',
      subtitle:
          'Long enough to forget the wording. Soon enough to remember why.',
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              const gap = 10.0;
              final width = (constraints.maxWidth - gap) / 2;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final option in const [
                    (3, '3 days', 'Quick check-in'),
                    (7, '1 week', 'Small plot twist'),
                    (14, '2 weeks', 'Fresh perspective'),
                    (30, '1 month', 'Notice the change'),
                    (90, '3 months', 'A new season'),
                    (180, '6 months', 'A wider view'),
                    (365, '1 year', 'Time capsule'),
                    (1095, '3 years', 'Long hello'),
                  ])
                    SizedBox(
                      width: width,
                      child: _DateOption(
                        title: option.$2,
                        subtitle: option.$3,
                        selected: !usesCustomDate && durationDays == option.$1,
                        isDark: isDark,
                        onTap: () => onDurationChanged(option.$1),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          Text(
            'Or choose the exact day',
            style: TextStyle(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 9),
          const SizedBox(height: 4),
          OutlinedButton.icon(
            onPressed: onCustomDate,
            icon: const Icon(Icons.calendar_month_outlined),
            label: Text(
              DateFormatter.formatShortDate(deliveryDate),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              foregroundColor: isDark ? AppColors.softOlive : _sage,
              side: BorderSide(
                color: (isDark ? AppColors.softOlive : _sage)
                    .withValues(alpha: 0.35),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(17),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _DateOption({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? (isDark ? AppColors.softOlive.withValues(alpha: 0.14) : _mist)
          : (isDark ? AppColors.darkCard : Colors.white),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? (isDark ? AppColors.softOlive : _sage)
                  : (isDark
                      ? AppColors.darkCardBorder
                      : const Color(0xFFE6E0D7)),
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                size: 19,
                color: selected
                    ? (isDark ? AppColors.softOlive : _sage)
                    : AppColors.textSecondaryLight,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style:
                            AppTypography.titleSmall(context, isDark: isDark)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style:
                            AppTypography.bodySmall(context, isDark: isDark)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewPage extends StatelessWidget {
  final bool isDark;
  final String title;
  final String message;
  final DateTime deliveryDate;

  const _ReviewPage({
    required this.isDark,
    required this.title,
    required this.message,
    required this.deliveryDate,
  });

  @override
  Widget build(BuildContext context) {
    return _PageFrame(
      eyebrow: 'ONE LAST LOOK',
      title: 'Ready to seal it?',
      subtitle: 'After this, curiosity has to practice patience.',
      isDark: isDark,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : _paper,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? AppColors.darkCardBorder : const Color(0xFFE3D9CC),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.mail_outline_rounded, color: _sage),
            const SizedBox(height: 18),
            Text(title,
                style: AppTypography.titleMedium(context, isDark: isDark)),
            const SizedBox(height: 10),
            Text(
              message,
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodyMedium(context, isDark: isDark),
            ),
            const SizedBox(height: 22),
            const Divider(height: 1),
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(Icons.schedule_rounded, size: 17, color: _sage),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Delivers ${DateFormatter.formatShortDate(deliveryDate)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall(context, isDark: isDark),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ComposerActions extends StatelessWidget {
  final int page;
  final bool saving;
  final bool isDark;
  final VoidCallback onBack;
  final VoidCallback onNext;

  const _ComposerActions({
    required this.page,
    required this.saving,
    required this.isDark,
    required this.onBack,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      child: Row(
        children: [
          if (page > 0) ...[
            OutlinedButton(
              onPressed: saving ? null : onBack,
              style: OutlinedButton.styleFrom(
                fixedSize: const Size(52, 52),
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(17),
                ),
              ),
              child: const Icon(Icons.arrow_back_rounded),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: FilledButton(
              key: const ValueKey('composer-next-button'),
              onPressed: saving ? null : onNext,
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                backgroundColor: AppColors.honeyAmber,
                foregroundColor: AppColors.onHoney,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(17),
                ),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: saving
                    ? const SizedBox(
                        key: ValueKey('saving'),
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Row(
                        key: ValueKey(page),
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              page == 3 ? 'Seal the letter' : 'Continue',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            page == 3
                                ? Icons.lock_outline_rounded
                                : Icons.arrow_forward_rounded,
                            size: 18,
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LetterReader extends StatefulWidget {
  final FutureLetter letter;

  const _LetterReader({required this.letter});

  @override
  State<_LetterReader> createState() => _LetterReaderState();
}

class _LetterReaderState extends State<_LetterReader> {
  late bool _revealed = widget.letter.isOpened;

  Future<void> _reveal() async {
    setState(() => _revealed = true);
    if (!widget.letter.isOpened) {
      await context
          .read<LettersProvider>()
          .updateLetter(widget.letter.copyWith(isOpened: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ready = widget.letter.isReadyToUnlock;
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.warmCream,
      appBar: AppBar(
        title: const Text('Future letter'),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 450),
          switchInCurve: Curves.easeOutCubic,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween(begin: const Offset(0, 0.025), end: Offset.zero)
                  .animate(animation),
              child: child,
            ),
          ),
          child: !ready
              ? _LockedLetter(
                  key: const ValueKey('locked'),
                  letter: widget.letter,
                  isDark: isDark)
              : !_revealed
                  ? _ArrivedLetter(
                      key: const ValueKey('arrived'),
                      letter: widget.letter,
                      isDark: isDark,
                      onReveal: _reveal,
                    )
                  : _RevealedLetter(
                      key: const ValueKey('revealed'),
                      letter: widget.letter,
                      isDark: isDark,
                    ),
        ),
      ),
    );
  }
}

class _LockedLetter extends StatelessWidget {
  final FutureLetter letter;
  final bool isDark;

  const _LockedLetter({super.key, required this.letter, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_clock_outlined, size: 44, color: _sage),
            const SizedBox(height: 22),
            Text(letter.title,
                textAlign: TextAlign.center,
                style: AppTypography.titleLarge(context, isDark: isDark)),
            const SizedBox(height: 10),
            Text(
              'Still in transit. It arrives ${DateFormatter.formatShortDate(letter.deliverAt)}.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium(context, isDark: isDark),
            ),
            const SizedBox(height: 8),
            Text(
              'No peeking. Character development is loading.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall(context, isDark: isDark),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArrivedLetter extends StatelessWidget {
  final FutureLetter letter;
  final bool isDark;
  final VoidCallback onReveal;

  const _ArrivedLetter(
      {super.key,
      required this.letter,
      required this.isDark,
      required this.onReveal});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : _mist,
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(Icons.mark_email_unread_outlined,
                  size: 36, color: _sage),
            ),
            const SizedBox(height: 24),
            Text('Right on time.',
                style: AppTypography.titleLarge(context, isDark: isDark)),
            const SizedBox(height: 9),
            Text(letter.title,
                textAlign: TextAlign.center,
                style: AppTypography.bodyLarge(context, isDark: isDark)),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: onReveal,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.honeyAmber,
                foregroundColor: AppColors.onHoney,
                minimumSize: const Size(210, 52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(17)),
              ),
              icon: const Icon(Icons.drafts_outlined),
              label: const Text('Open letter',
                  style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }
}

class _RevealedLetter extends StatelessWidget {
  final FutureLetter letter;
  final bool isDark;

  const _RevealedLetter(
      {super.key, required this.letter, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 48),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : _paper,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
              color:
                  isDark ? AppColors.darkCardBorder : const Color(0xFFE3D9CC)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.mail_outline_rounded, color: _sage),
            const SizedBox(height: 24),
            Text(letter.title,
                style: AppTypography.titleLarge(context, isDark: isDark)),
            const SizedBox(height: 8),
            Text(
              'Written ${DateFormatter.formatShortDate(letter.createdAt)}',
              style: AppTypography.bodySmall(context, isDark: isDark),
            ),
            const SizedBox(height: 24),
            Divider(
                color: isDark
                    ? AppColors.darkCardBorder
                    : const Color(0xFFDCD2C5)),
            const SizedBox(height: 24),
            SelectableText(
              letter.content,
              style: AppTypography.bodyLarge(context, isDark: isDark)
                  .copyWith(height: 1.75),
            ),
          ],
        ),
      ),
    );
  }
}

InputDecoration _fieldDecoration({
  required bool isDark,
  required String hint,
  required IconData icon,
  bool alignTop = false,
}) {
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(20),
    borderSide: BorderSide(
      color: isDark ? AppColors.darkCardBorder : const Color(0xFFE2DCD2),
    ),
  );
  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(
      color: isDark ? AppColors.textSecondaryDark : const Color(0xFF9A958D),
    ),
    prefixIcon: Padding(
      padding: EdgeInsets.only(top: alignTop ? 14 : 0),
      child: Icon(icon, color: isDark ? AppColors.softOlive : _sage),
    ),
    prefixIconConstraints: BoxConstraints(
      minWidth: 52,
      minHeight: alignTop ? 52 : 0,
    ),
    filled: true,
    fillColor: isDark ? AppColors.darkCard : Colors.white,
    enabledBorder: border,
    focusedBorder: border.copyWith(
      borderSide:
          BorderSide(color: isDark ? AppColors.softOlive : _sage, width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
  );
}
