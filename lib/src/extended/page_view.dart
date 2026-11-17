import 'package:clean_tab_view/src/extended/scrollable.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

part 'package:clean_tab_view/src/official/page_view.dart';

class ExtendedPageView extends _PageView {
  ExtendedPageView({
    super.key,
    super.scrollDirection = Axis.horizontal,
    super.reverse = false,
    super.controller,
    super.physics,
    super.pageSnapping = true,
    super.onPageChanged,
    super.children = const <Widget>[],
    super.dragStartBehavior = DragStartBehavior.start,
    super.allowImplicitScrolling = false,
    super.restorationId,
    super.clipBehavior = Clip.hardEdge,
    super.scrollBehavior,
    super.padEnds = true,
    this.cacheExtent = 0,
    this.shouldIgnorePointerWhenScrolling = false,
  });

  ExtendedPageView.builder({
    super.key,
    super.scrollDirection = Axis.horizontal,
    super.reverse = false,
    super.controller,
    super.physics,
    super.pageSnapping = true,
    super.onPageChanged,
    required super.itemBuilder,
    super.findChildIndexCallback,
    super.itemCount,
    super.dragStartBehavior = DragStartBehavior.start,
    super.allowImplicitScrolling = false,
    super.restorationId,
    super.clipBehavior = Clip.hardEdge,
    super.scrollBehavior,
    super.padEnds = true,
    this.cacheExtent = 0,
    this.shouldIgnorePointerWhenScrolling = false,
  }) : super.builder();

  ExtendedPageView.custom({
    super.key,
    super.scrollDirection = Axis.horizontal,
    super.reverse = false,
    super.controller,
    super.physics,
    super.pageSnapping = true,
    super.onPageChanged,
    required super.childrenDelegate,
    super.dragStartBehavior = DragStartBehavior.start,
    super.allowImplicitScrolling = false,
    super.restorationId,
    super.clipBehavior = Clip.hardEdge,
    super.scrollBehavior,
    super.padEnds = true,
    this.cacheExtent = 0,
    this.shouldIgnorePointerWhenScrolling = false,
  }) : super.custom();

  final int cacheExtent;

  final bool shouldIgnorePointerWhenScrolling;

  @override
  State<ExtendedPageView> createState() => _ExtendedPageViewState();
}

class _ExtendedPageViewState extends _PageViewState<ExtendedPageView> {
  @override
  Widget build(BuildContext context) {
    final AxisDirection axisDirection = _getDirection(context);

    final ScrollPhysics physics =
        _ForceImplicitScrollPhysics(
          allowImplicitScrolling: widget.allowImplicitScrolling,
        ).applyTo(
          widget.pageSnapping
              ? _kPagePhysics.applyTo(
                  widget.physics ??
                      widget.scrollBehavior?.getScrollPhysics(context),
                )
              : widget.physics ??
                    widget.scrollBehavior?.getScrollPhysics(context),
        );

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification notification) {
        if (notification.depth == 0 &&
            widget.onPageChanged != null &&
            notification is ScrollUpdateNotification) {
          final PageMetrics metrics = notification.metrics as PageMetrics;
          final int currentPage = metrics.page!.round();
          if (currentPage != _lastReportedPage) {
            _lastReportedPage = currentPage;
            widget.onPageChanged!(currentPage);
          }
        }
        return false;
      },
      child: ExtendedScrollable(
        shouldIgnorePointerWhenScrolling:
            widget.shouldIgnorePointerWhenScrolling,
        dragStartBehavior: widget.dragStartBehavior,
        axisDirection: axisDirection,
        controller: widget.controller,
        physics: physics,
        restorationId: widget.restorationId,
        scrollBehavior:
            widget.scrollBehavior ??
            ScrollConfiguration.of(context).copyWith(scrollbars: false),
        viewportBuilder: (BuildContext context, ViewportOffset position) {
          return Viewport(
            // https://github.com/flutter/flutter/issues/45632
            scrollCacheExtent: ScrollCacheExtent.viewport(
              widget.cacheExtent > 0
                  ? widget.cacheExtent.toDouble()
                  : (widget.allowImplicitScrolling ? 1.0 : 0.0),
            ),
            axisDirection: axisDirection,
            offset: position,
            clipBehavior: widget.clipBehavior,
            slivers: <Widget>[
              SliverFillViewport(
                viewportFraction: widget.controller.viewportFraction,
                delegate: widget.childrenDelegate,
                padEnds: widget.padEnds,
                allowImplicitScrolling: widget.allowImplicitScrolling,
              ),
            ],
          );
        },
      ),
    );
  }
}
