import 'package:clean_tab_view/src/gestures/drag_hold_controller.dart';
import 'package:clean_tab_view/src/gestures/link_scroll_state.dart';
import 'package:clean_tab_view/src/gestures/sync_controller.dart';
import 'package:flutter/widgets.dart';

class LinkScrollController extends ScrollController
    with LinkScrollControllerMixin {
  @override
  final LinkScrollControllerMixin? parent;

  LinkScrollController({
    super.initialScrollOffset,
    super.keepScrollOffset,
    super.debugLabel,
    this.parent,
  });
}

class LinkPageController extends PageController with LinkScrollControllerMixin {
  @override
  final LinkScrollControllerMixin? parent;

  LinkPageController({
    super.initialPage,
    super.keepPage,
    super.viewportFraction,
    this.parent,
  });
}

mixin LinkScrollControllerMixin on ScrollController
    implements SyncScrollControllerMixin {
  late final SyncScrollHandler _syncHandler = SyncScrollHandler();

  LinkScrollControllerMixin? get parent;

  LinkScrollControllerMixin? _parent;

  LinkScrollControllerMixin? get _internalParent => parent ?? _parent;

  LinkScrollControllerMixin? _activedLinkParent;

  bool get parentIsNotNull => _internalParent != null;

  bool get isSelf => _activedLinkParent == null;

  void linkParent<S extends StatefulWidget, T extends LinkScrollState<S>>(
    BuildContext context,
  ) {
    _parent = context.findAncestorStateOfType<T>()?.linkScrollController;
  }

  void unlinkParent() {
    _parent = null;
  }

  @override
  void handleDragDown(DragDownDetails? details) {
    _syncHandler.handleDragDown(details);
  }

  @override
  void handleDragStart(DragStartDetails details) {
    _syncHandler.handleDragStart(details);
  }

  @override
  void handleDragUpdate(DragUpdateDetails details) {
    if (_activedLinkParent != null && _activedLinkParent!.hasDrag) {
      _activedLinkParent!.handleDragUpdate(details);
    } else {
      _syncHandler.handleDragUpdate(details);
    }
  }

  @override
  void handleDragEnd(DragEndDetails details) {
    _activedLinkParent?.handleDragEnd(details);
    _syncHandler.handleDragEnd(details);
  }

  @override
  void handleDragCancel() {
    _activedLinkParent?.handleDragCancel();
    _activedLinkParent = null;
    _syncHandler.handleDragCancel();
  }

  @override
  void forceCancel() {
    _activedLinkParent?.forceCancel();
    _activedLinkParent = null;
    _syncHandler.forceCancel();
  }

  double get extentAfter => _activedLinkParent != null
      ? _activedLinkParent!.extentAfter
      : _extentAfter;

  double get extentBefore => _activedLinkParent != null
      ? _activedLinkParent!.extentBefore
      : _extentBefore;

  double get _extentAfter => _syncHandler.positionToListener.keys.isEmpty
      ? 0
      : _syncHandler.positionToListener.keys.first.extentAfter;

  double get _extentBefore => _syncHandler.positionToListener.keys.isEmpty
      ? 0
      : _syncHandler.positionToListener.keys.first.extentBefore;

  bool get hasDrag =>
      _activedLinkParent != null ? _activedLinkParent!.hasDrag : _hasDrag;

  bool get hasHold =>
      _activedLinkParent != null ? _activedLinkParent!.hasHold : _hasHold;

  bool get _hasDrag => _syncHandler.positionToListener.values.any(
    (DragHoldController element) => element.hasDrag,
  );

  bool get _hasHold => _syncHandler.positionToListener.values.any(
    (DragHoldController element) => element.hasHold,
  );

  LinkScrollControllerMixin? _findParent(
    bool Function(LinkScrollControllerMixin parent) test,
  ) {
    if (_internalParent == null) {
      return null;
    }

    if (test(_internalParent!)) {
      return _internalParent!;
    }

    return _internalParent!._findParent(test);
  }

  void linkActivedParent(
    double delta,
    DragUpdateDetails details,
    TextDirection textDirection,
  ) {
    if (_activedLinkParent != null) {
      return;
    }

    LinkScrollControllerMixin? activedParent;
    if (textDirection == TextDirection.rtl) {
      delta = -delta;
    }

    if (delta < 0 && _extentAfter == 0) {
      activedParent = _findParent(
        (LinkScrollControllerMixin parent) => parent._extentAfter != 0,
      );
    } else if (delta > 0 && _extentBefore == 0) {
      activedParent = _findParent(
        (LinkScrollControllerMixin parent) => parent._extentBefore != 0,
      );
    }

    if (activedParent != null) {
      _activedLinkParent = activedParent;

      activedParent.handleDragDown(null);

      activedParent.handleDragStart(
        DragStartDetails(
          globalPosition: details.globalPosition,
          localPosition: details.localPosition,
          sourceTimeStamp: details.sourceTimeStamp,
        ),
      );
    }
  }

  @override
  void attach(ScrollPosition position) {
    super.attach(position);

    _syncHandler.attach(position);
  }

  @override
  void detach(ScrollPosition position) {
    _syncHandler.detach(position);

    super.detach(position);
  }

  @override
  void dispose() {
    _syncHandler.forceCancel();

    super.dispose();
  }
}
