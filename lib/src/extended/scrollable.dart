import 'package:flutter/widgets.dart';

class ExtendedScrollable extends Scrollable {
  const ExtendedScrollable({
    super.key,
    super.axisDirection,
    super.controller,
    super.physics,
    required super.viewportBuilder,
    super.incrementCalculator,
    super.excludeFromSemantics,
    super.semanticChildCount,
    super.dragStartBehavior,
    super.restorationId,
    super.scrollBehavior,
    this.shouldIgnorePointerWhenScrolling = false,
  });

  final bool shouldIgnorePointerWhenScrolling;

  @override
  ExtendedScrollableState createState() => ExtendedScrollableState();
}

class ExtendedScrollableState extends ScrollableState {
  @override
  void setIgnorePointer(bool value) {
    final ExtendedScrollable scrollable = widget as ExtendedScrollable;
    if (scrollable.shouldIgnorePointerWhenScrolling) {
      super.setIgnorePointer(value);
    }
  }
}
