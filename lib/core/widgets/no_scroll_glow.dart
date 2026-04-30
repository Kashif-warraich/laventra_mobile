import 'package:flutter/material.dart';

/// Hides the scrollbar and the Material overscroll glow. Wrap a scrollable
/// (or the whole MaterialApp via `scrollBehavior`) for the design's
/// hidden-scrollbar effect.
class NoScrollGlow extends ScrollBehavior {
  const NoScrollGlow();

  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) => child;

  @override
  Widget buildScrollbar(BuildContext context, Widget child, ScrollableDetails details) => child;
}
