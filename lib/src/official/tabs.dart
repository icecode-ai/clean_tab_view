// ignore_for_file: require_trailing_commas

part of 'package:clean_tab_view/src/extended/tabs.dart';

class _TabBarView extends StatefulWidget {
  const _TabBarView({
    super.key,
    required this.children,
    this.controller,
    this.physics,
    this.dragStartBehavior = DragStartBehavior.start,
    this.viewportFraction = 1.0,
    this.clipBehavior = Clip.hardEdge,
  });

  /// todo check, update by doersoul@126.com
  final ExtendedTabController? controller;

  final List<Widget> children;

  final ScrollPhysics? physics;

  final DragStartBehavior dragStartBehavior;

  final double viewportFraction;

  final Clip clipBehavior;

  @override
  State<_TabBarView> createState() => _TabBarViewState();
}

class _TabBarViewState<T extends _TabBarView> extends LinkScrollState<T> {
  TabController? _controller;
  late PageController _pageController;
  late List<Widget> _childrenWithKey;
  int? _currentIndex;
  int _warpUnderwayCount = 0;
  int _scrollUnderwayCount = 0;
  bool _debugHasScheduledValidChildrenCountCheck = false;

  bool get _controllerIsValid => _controller?.animation != null;

  /// todo check, add by doersoul@126.com
  bool get _isJump {
    if (_controller == null || _controller is! ExtendedTabController) {
      return false;
    }

    return (_controller as ExtendedTabController).jump;
  }

  void _updateTabController() {
    final TabController? newController =
        widget.controller ?? DefaultTabController.maybeOf(context);

    assert(() {
      if (newController == null) {
        throw FlutterError(
          'No TabController for ${widget.runtimeType}.\n'
          'When creating a ${widget.runtimeType}, you must either provide an explicit '
          'TabController using the "controller" property, or you must ensure that there '
          'is a DefaultTabController above the ${widget.runtimeType}.\n'
          'In this case, there was neither an explicit controller nor a default controller.',
        );
      }
      return true;
    }());

    if (newController == _controller) {
      return;
    }

    if (_controllerIsValid) {
      _controller!.animation!.removeListener(_handleTabControllerAnimationTick);
    }

    _controller = newController;
    if (_controller != null) {
      _controller!.animation!.addListener(_handleTabControllerAnimationTick);
    }
  }

  void _jumpToPage(int page) {
    _warpUnderwayCount += 1;
    _pageController.jumpToPage(page);
    _warpUnderwayCount -= 1;
  }

  Future<void> _animateToPage(
    int page, {
    required Duration duration,
    required Curve curve,
  }) async {
    _warpUnderwayCount += 1;
    await _pageController.animateToPage(page, duration: duration, curve: curve);
    _warpUnderwayCount -= 1;
  }

  @override
  void initState() {
    super.initState();
    _updateChildren();
  }

  @override
  void didUpdateWidget(T oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.controller != oldWidget.controller) {
      _updateTabController();
      _currentIndex = _controller!.index;
      _jumpToPage(_currentIndex!);
    }

    if (widget.children != oldWidget.children && _warpUnderwayCount == 0) {
      _updateChildren();
    }
  }

  @override
  void dispose() {
    if (_controllerIsValid) {
      _controller!.animation!.removeListener(_handleTabControllerAnimationTick);
    }

    _controller = null;

    super.dispose();
  }

  void _updateChildren() {
    _childrenWithKey = KeyedSubtree.ensureUniqueKeysForList(
      widget.children.map<Widget>((Widget child) {
        return Semantics(role: SemanticsRole.tabPanel, child: child);
      }).toList(),
    );
  }

  void _handleTabControllerAnimationTick() {
    if (_scrollUnderwayCount > 0 || !_controller!.indexIsChanging) {
      return;
    }

    if (_controller!.index != _currentIndex) {
      _currentIndex = _controller!.index;

      _warpToCurrentIndex();
    }
  }

  void _warpToCurrentIndex() {
    if (!mounted || _pageController.page == _currentIndex!.toDouble()) {
      return;
    }

    final bool adjacentDestination =
        (_currentIndex! - _controller!.previousIndex).abs() == 1;
    if (adjacentDestination) {
      _warpToAdjacentTab(_controller!.animationDuration);
    } else {
      _warpToNonAdjacentTab(_controller!.animationDuration);
    }
  }

  Future<void> _warpToAdjacentTab(Duration duration) async {
    // todo check, update by doersoul@126.com
    if (_isJump || duration == Duration.zero) {
      _jumpToPage(_currentIndex!);
    } else {
      await _animateToPage(
        _currentIndex!,
        duration: duration,
        curve: Curves.ease,
      );
    }

    if (mounted) {
      setState(_updateChildren);
    }

    return Future<void>.value();
  }

  Future<void> _warpToNonAdjacentTab(Duration duration) async {
    final int previousIndex = _controller!.previousIndex;

    assert((_currentIndex! - previousIndex).abs() > 1);

    final int initialPage = _currentIndex! > previousIndex
        ? _currentIndex! - 1
        : _currentIndex! + 1;

    setState(() {
      _childrenWithKey = List<Widget>.of(_childrenWithKey, growable: false);

      final Widget temp = _childrenWithKey[initialPage];

      _childrenWithKey[initialPage] = _childrenWithKey[previousIndex];
      _childrenWithKey[previousIndex] = temp;
    });

    // todo check, update by doersoul@126.com
    if (_isJump || duration == Duration.zero) {
      _jumpToPage(_currentIndex!);
    } else {
      _jumpToPage(initialPage);

      await _animateToPage(
        _currentIndex!,
        duration: duration,
        curve: Curves.ease,
      );
    }

    if (mounted) {
      setState(_updateChildren);
    }
  }

  void _syncControllerOffset() {
    _controller!.offset = clampDouble(
      _pageController.page! - _controller!.index,
      -1.0,
      1.0,
    );
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (_warpUnderwayCount > 0 || _scrollUnderwayCount > 0) {
      return false;
    }

    if (notification.depth != 0) {
      return false;
    }

    if (!_controllerIsValid) {
      return false;
    }

    _scrollUnderwayCount += 1;

    final double page = _pageController.page!;

    if (notification is ScrollUpdateNotification &&
        !_controller!.indexIsChanging) {
      final bool pageChanged = (page - _controller!.index).abs() > 1.0;
      if (pageChanged) {
        _controller!.index = page.round();
        _currentIndex = _controller!.index;
      }

      _syncControllerOffset();
    } else if (notification is ScrollEndNotification) {
      _controller!.index = page.round();
      _currentIndex = _controller!.index;

      if (!_controller!.indexIsChanging) {
        _syncControllerOffset();
      }
    }

    _scrollUnderwayCount -= 1;

    return false;
  }

  bool _debugScheduleCheckHasValidChildrenCount() {
    if (_debugHasScheduledValidChildrenCountCheck) {
      return true;
    }

    WidgetsBinding.instance.addPostFrameCallback((Duration duration) {
      _debugHasScheduledValidChildrenCountCheck = false;

      if (!mounted) {
        return;
      }

      assert(() {
        if (_controller!.length != widget.children.length) {
          throw FlutterError(
            "Controller's length property (${_controller!.length}) does not match the "
            "number of children (${widget.children.length}) present in TabBarView's children property.",
          );
        }

        return true;
      }());
    }, debugLabel: 'TabBarView.validChildrenCountCheck');

    _debugHasScheduledValidChildrenCountCheck = true;

    return true;
  }

  @override
  Widget build(BuildContext context) {
    assert(_debugScheduleCheckHasValidChildrenCount());

    return NotificationListener<ScrollNotification>(
      onNotification: _handleScrollNotification,
      child: PageView(
        dragStartBehavior: widget.dragStartBehavior,
        clipBehavior: widget.clipBehavior,
        controller: _pageController,
        physics: widget.physics == null
            ? const PageScrollPhysics().applyTo(const ClampingScrollPhysics())
            : const PageScrollPhysics().applyTo(widget.physics),
        children: _childrenWithKey,
      ),
    );
  }

  @override
  bool get link => throw UnimplementedError();

  @override
  LinkScrollControllerMixin get linkScrollController =>
      throw UnimplementedError();

  @override
  ScrollPhysics? get physics => throw UnimplementedError();

  @override
  Axis get scrollDirection => throw UnimplementedError();
}
