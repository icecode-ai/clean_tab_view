import 'dart:ui' show SemanticsRole;

import 'package:clean_tab_view/src/extended/page_view.dart';
import 'package:clean_tab_view/src/extended/tab_controller.dart';
import 'package:clean_tab_view/src/gestures/link_controller.dart';
import 'package:clean_tab_view/src/gestures/link_scroll_state.dart';
import 'package:clean_tab_view/src/gestures/scroll_physics.dart';
import 'package:clean_tab_view/src/official/tab_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

part 'package:clean_tab_view/src/official/tabs.dart';

const ScrollPhysics _defaultScrollPhysics = NeverScrollableScrollPhysics();

typedef ExtendedTransformer = Widget Function(Widget cld, int idx, double pos);

final Widget _edge = GestureDetector(
  behavior: HitTestBehavior.opaque,
  child: const SizedBox(width: 20, height: double.infinity),
);

class ExtendedTabBarView extends _TabBarView {
  const ExtendedTabBarView({
    super.key,
    required super.children,
    required super.controller,
    super.physics = extendedScrollPhysics,
    super.dragStartBehavior = DragStartBehavior.start,
    super.viewportFraction = 1.0,
    super.clipBehavior = Clip.hardEdge,
    this.cacheExtent = 0,
    this.link = true,
    this.shouldIgnorePointerWhenScrolling = false,
    this.scrollDirection = Axis.horizontal,
    this.keepTab = false,
    this.onTabChanging,
    this.onTabActive,
    this.onDragTab,
    this.transformer,
    this.addEdge = false,
  });

  /// cache page count
  /// default is 0.
  /// if cacheExtent is 1, it has two pages in cache
  final int cacheExtent;

  final bool link;

  final bool shouldIgnorePointerWhenScrolling;

  final Axis scrollDirection;

  final bool keepTab;

  final ValueChanged<double>? onTabChanging;

  final ValueChanged<int>? onTabActive;

  final ValueChanged<bool>? onDragTab;

  final ExtendedTransformer? transformer;

  final bool addEdge;

  @override
  State<ExtendedTabBarView> createState() => ExtendedTabBarViewState();
}

class ExtendedTabBarViewState extends _TabBarViewState<ExtendedTabBarView> {
  final ValueNotifier<double> _position = ValueNotifier(-1);

  int _currentTabBarViewIndex = 0;

  bool _pageControllerCreated = false;

  @override
  bool get link => widget.link;

  @override
  LinkScrollControllerMixin get linkScrollController =>
      _pageController as LinkPageController;

  @override
  ScrollPhysics? get physics => widget.physics;

  @override
  Axis get scrollDirection => widget.scrollDirection;

  @override
  void didChangeDependencies() {
    _updateTabController();

    _currentIndex = _controller!.index;
    _currentTabBarViewIndex = _controller!.index;

    if (!_pageControllerCreated) {
      _pageControllerCreated = true;

      _pageController = LinkPageController(
        initialPage: _currentIndex ?? 0,
        viewportFraction: widget.viewportFraction,
        keepPage: widget.keepTab,
      );

      _pageController.addListener(_pageListener);
    }

    super.didChangeDependencies();
  }

  @override
  void didUpdateWidget(covariant ExtendedTabBarView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.controller != oldWidget.controller) {
      _currentTabBarViewIndex = _controller!.index;
    }

    if (widget.physics != oldWidget.physics) {
      updatePhysics();
    }

    if (oldWidget.scrollDirection != widget.scrollDirection ||
        oldWidget.physics != widget.physics) {
      initGestureRecognizers();
    }
  }

  @override
  void dispose() {
    _pageController.removeListener(_pageListener);

    _pageController.dispose();

    _position.dispose();

    super.dispose();
  }

  @override
  ScrollPhysics? getScrollPhysics() {
    return _defaultScrollPhysics.applyTo(
      widget.physics == null
          ? const ClampingScrollPhysics()
          : const ClampingScrollPhysics().applyTo(widget.physics),
    );
  }

  @override
  // ignore: unnecessary_overrides
  void linkParent<S extends StatefulWidget, T extends LinkScrollState<S>>() {
    super.linkParent<ExtendedTabBarView, ExtendedTabBarViewState>();
  }

  @override
  _updateChildren() {
    if (widget.transformer != null) {
      final List<Widget> children = [];
      for (int index = 0; index < widget.children.length; index++) {
        final Widget item = widget.children[index];

        children.add(
          Semantics(
            role: SemanticsRole.tabPanel,
            child: AnimatedBuilder(
              animation: _position,
              builder: (BuildContext context, Widget? child) {
                return widget.transformer!.call(child!, index, _position.value);
              },
              child: item,
            ),
          ),
        );
      }

      _childrenWithKey = KeyedSubtree.ensureUniqueKeysForList(children);
    } else {
      _childrenWithKey = KeyedSubtree.ensureUniqueKeysForList(
        widget.children.map<Widget>((Widget child) {
          return Semantics(role: SemanticsRole.tabPanel, child: child);
        }).toList(),
      );
    }
  }

  void _pageListener() {
    _position.value = linkScrollController.offset;

    widget.onDragTab?.call(linkScrollController.hasDrag);

    double? page = _pageController.page;
    if (page != null && page != _currentTabBarViewIndex) {
      widget.onTabChanging?.call(page);

      int round = page.round();
      if (round != _currentTabBarViewIndex) {
        _currentTabBarViewIndex = round;

        widget.onTabActive?.call(round);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    assert(() {
      if (_controller!.length != widget.children.length) {
        throw FlutterError(
          'Controller\'s length property (${_controller!.length}) does not match the \n'
          'number of tabs (${widget.children.length}) present in TabBar\'s tabs property.',
        );
      }

      return true;
    }());

    final result = NotificationListener<ScrollNotification>(
      onNotification: _handleScrollNotification,
      child: NotificationListener<OverscrollIndicatorNotification>(
        onNotification: _handleGlowNotification,
        child: ExtendedPageView(
          dragStartBehavior: widget.dragStartBehavior,
          controller: _pageController,
          cacheExtent: widget.cacheExtent,
          scrollDirection: widget.scrollDirection,
          physics: usedScrollPhysics,
          shouldIgnorePointerWhenScrolling:
              widget.shouldIgnorePointerWhenScrolling,
          children: _childrenWithKey,
        ),
      ),
    );

    Widget tabview = buildGestureDetector(child: result);

    if (widget.addEdge) {
      tabview = Stack(
        children: [
          tabview,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [_edge, _edge],
          ),
        ],
      );
    }

    return tabview;
  }

  bool _handleGlowNotification(OverscrollIndicatorNotification notification) {
    if (notification.depth == 0 &&
        !(_pageController as LinkPageController).isSelf) {
      notification.disallowIndicator();

      return true;
    }

    return false;
  }
}
