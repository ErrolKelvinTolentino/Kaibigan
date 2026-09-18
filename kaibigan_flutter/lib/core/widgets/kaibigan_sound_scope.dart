import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../services/ui_sound_service.dart';

/// Makes the interface audible without every widget having to ask.
///
/// Wrapping the app in one scope is the only way to cover "every tap" without
/// editing hundreds of call sites — and without a rule that new screens would
/// quietly forget to follow. A pointer that goes down and up in roughly the
/// same place, on something that declares a tap action, gets the soft cue.
/// Everything else — scrolling, dragging, a press on plain text — stays silent.
class KaibiganSoundScope extends StatefulWidget {
  const KaibiganSoundScope({
    super.key,
    required this.controller,
    required this.child,
  });

  final UiSoundController controller;
  final Widget child;

  /// The nearest sound controller, for playing a cue that carries meaning —
  /// a save, a completion, a nudge. Returns null outside a scope so widgets
  /// used in isolation (and in tests) keep working.
  static UiSoundController? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<_SoundScopeMarker>()
      ?.controller;

  /// Plays [sound] if this subtree has a controller. A no-op otherwise, so
  /// call sites never need a null check.
  static void play(BuildContext context, UiSound sound) =>
      maybeOf(context)?.play(sound);

  /// Whether a completed pointer gesture was a tap worth answering.
  ///
  /// Kept as a pure rule so it can be verified directly: the widget test
  /// harness synthesises pointer events with a zero timestamp, so the
  /// duration condition cannot be exercised through a simulated gesture.
  static bool isTapGesture({
    required Offset downPosition,
    required Offset upPosition,
    required Duration held,
    required bool scrolled,
  }) {
    if (scrolled) return false;
    if ((upPosition - downPosition).distance > _tapSlop) return false;
    // Flutter promotes a held pointer to a long press at [kLongPressTimeout],
    // so anything reaching it is by definition no longer a tap.
    return held < kLongPressTimeout;
  }

  /// How far a pointer may travel and still count as a tap rather than a drag.
  static const double _tapSlop = 14;

  @override
  State<KaibiganSoundScope> createState() => _KaibiganSoundScopeState();
}

class _KaibiganSoundScopeState extends State<KaibiganSoundScope> {
  Offset? _downPosition;

  /// Taken from the pointer events themselves rather than the wall clock, so
  /// the measurement is the gesture's own duration and not however long the
  /// frame took to deliver it.
  Duration? _downTimeStamp;
  bool _scrolledSinceDown = false;

  void _onPointerDown(PointerDownEvent event) {
    _downPosition = event.position;
    _downTimeStamp = event.timeStamp;
    _scrolledSinceDown = false;
  }

  void _onPointerUp(PointerUpEvent event) {
    final start = _downPosition;
    final startedAt = _downTimeStamp;
    _downPosition = null;
    _downTimeStamp = null;
    if (start == null || startedAt == null) return;
    if (!KaibiganSoundScope.isTapGesture(
      downPosition: start,
      upPosition: event.position,
      held: event.timeStamp - startedAt,
      scrolled: _scrolledSinceDown,
    )) {
      return;
    }
    if (!_hitsSomethingTappable(event)) return;
    widget.controller.play(UiSound.tap);
  }

  /// True when the release landed on a widget that declares a tap action.
  ///
  /// Reading the semantics layer rather than guessing from widget types means
  /// this covers buttons, chips, list tiles, cards and anything custom built
  /// on [GestureDetector] — and skips scroll views, which declare drag
  /// actions but no tap.
  bool _hitsSomethingTappable(PointerUpEvent event) {
    try {
      final result = HitTestResult();
      GestureBinding.instance.hitTestInView(result, event.position, event.viewId);
      for (final entry in result.path) {
        final target = entry.target;
        // Widgets built directly on GestureDetector.
        if (target is RenderSemanticsGestureHandler && target.onTap != null) {
          return true;
        }
        // Material's own controls annotate the tap action instead. A disabled
        // control drops the action entirely, which is exactly the behaviour we
        // want: pressing a greyed-out button should stay silent.
        if (target is RenderSemanticsAnnotations &&
            target.properties.onTap != null) {
          return true;
        }
      }
    } catch (_) {
      // A hit test should never be the reason an interaction fails.
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      // A tap that began a scroll is not a tap. Flagging it here is simpler and
      // more reliable than trying to infer it from pointer movement alone.
      onNotification: (notification) {
        if (notification is ScrollUpdateNotification ||
            notification is ScrollStartNotification) {
          _scrolledSinceDown = true;
        }
        return false;
      },
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: _onPointerDown,
        onPointerUp: _onPointerUp,
        onPointerCancel: (_) {
          _downPosition = null;
          _downTimeStamp = null;
        },
        child: _SoundScopeMarker(
          controller: widget.controller,
          level: widget.controller.level,
          child: widget.child,
        ),
      ),
    );
  }
}

class _SoundScopeMarker extends InheritedWidget {
  const _SoundScopeMarker({
    required this.controller,
    required this.level,
    required super.child,
  });

  final UiSoundController controller;

  /// Held so a level change rebuilds dependents (the settings preview, mainly).
  final UiSoundLevel level;

  @override
  bool updateShouldNotify(_SoundScopeMarker oldWidget) =>
      oldWidget.controller != controller || oldWidget.level != level;
}

/// Gives screens, dialogs and bottom sheets their arrival cue.
///
/// Attached once to the app's navigator, so a new surface sounds the same
/// wherever it is pushed from — including routes added later that know
/// nothing about sound.
class KaibiganSoundNavigatorObserver extends NavigatorObserver {
  KaibiganSoundNavigatorObserver(this.controller);

  final UiSoundController controller;

  bool _isUserFacing(Route<dynamic>? route) =>
      route is PageRoute || route is PopupRoute;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    // The very first route is the app opening, which already has the splash.
    if (previousRoute == null || !_isUserFacing(route)) return;
    controller.play(UiSound.open);
  }
}
