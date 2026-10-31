import 'package:flutter/material.dart';

typedef JournalReplyRevealBuilder = Widget Function(
  BuildContext context,
  String visibleText,
  bool isRevealing,
  VoidCallback showFullReply,
);

/// Presentation only: the complete reply stays available for saving and copying.
class JournalReplyReveal extends StatefulWidget {
  const JournalReplyReveal({
    super.key,
    required this.text,
    required this.animate,
    required this.revision,
    required this.builder,
  });

  final String text;
  final bool animate;
  final int revision;
  final JournalReplyRevealBuilder builder;

  @override
  State<JournalReplyReveal> createState() => _JournalReplyRevealState();
}

class _JournalReplyRevealState extends State<JournalReplyReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;
  List<int> _wordEnds = const [];
  int _visibleWords = 0;
  bool _started = false;

  bool get _reduceMotion =>
      MediaQuery.disableAnimationsOf(context) ||
      MediaQuery.accessibleNavigationOf(context);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, value: 1)
      ..addListener(_updateVisibleWords);
    _opacity = _controller.drive(CurveTween(
      curve: const Interval(0, 0.22, curve: Curves.easeOut),
    ));
    _offset = _controller
        .drive(CurveTween(
          curve: const Interval(0, 0.3, curve: Curves.easeOutCubic),
        ))
        .drive(Tween(begin: const Offset(0, 0.025), end: Offset.zero));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _startReveal();
    } else if (_reduceMotion) {
      _showFullReply();
    }
  }

  @override
  void didUpdateWidget(JournalReplyReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text ||
        oldWidget.revision != widget.revision ||
        oldWidget.animate != widget.animate) {
      _startReveal();
    }
  }

  void _startReveal() {
    _started = true;
    // Word boundaries preserve emoji, combining marks, and Filipino text.
    _wordEnds = RegExp(r'\S+\s*')
        .allMatches(widget.text)
        .map((match) => match.end)
        .toList(growable: false);
    if (!widget.animate || _reduceMotion || _wordEnds.isEmpty) {
      _showFullReply();
      return;
    }
    _controller.duration = Duration(
      milliseconds: (_wordEnds.length * 26).clamp(600, 2800),
    );
    _visibleWords = 0;
    _controller.forward(from: 0);
  }

  void _updateVisibleWords() {
    final count = (_controller.value * _wordEnds.length).ceil();
    // Reparse only the active reply when a word arrives, not the conversation.
    if (count != _visibleWords || _controller.value == 1) {
      setState(() => _visibleWords = count);
    }
  }

  void _showFullReply() {
    _controller.stop();
    _controller.value = 1;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isRevealing = _controller.value < 1;
    final visibleText = !isRevealing
        ? widget.text
        : _visibleWords == 0
            ? ''
            : widget.text.substring(0, _wordEnds[_visibleWords - 1]);
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _offset,
        child:
            widget.builder(context, visibleText, isRevealing, _showFullReply),
      ),
    );
  }
}
