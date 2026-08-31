import 'package:flutter/material.dart';

/// Shared phone-first sizing rules used across Kaibigan.
///
/// Pages remain edge-to-edge, while readable content is centered and capped on
/// unusually wide devices. This does not introduce persistent navigation.
abstract final class MobileLayout {
  static const double maxContentWidth = 600;
  static const double minimumTouchTarget = 48;

  static double horizontalPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width <= 340) return 14;
    if (width <= 390) return 16;
    return 20;
  }

  static EdgeInsets pageInsets(
    BuildContext context, {
    double top = 16,
    double bottom = 24,
  }) {
    final horizontal = horizontalPadding(context);
    return EdgeInsets.fromLTRB(horizontal, top, horizontal, bottom);
  }
}

class MobileContent extends StatelessWidget {
  const MobileContent({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.alignment = Alignment.topCenter,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: MobileLayout.maxContentWidth,
        ),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Makes tall sheet content scroll instead of overflowing on compact phones or
/// when accessibility text is enlarged.
class MobileSheetBody extends StatelessWidget {
  const MobileSheetBody({
    super.key,
    required this.child,
    this.topMargin = 40,
  });

  final Widget child;
  final double topMargin;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(top: topMargin),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: media.size.height -
                media.viewPadding.top -
                topMargin.clamp(16, 64),
          ),
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            physics: const ClampingScrollPhysics(),
            child: child,
          ),
        ),
      ),
    );
  }
}
