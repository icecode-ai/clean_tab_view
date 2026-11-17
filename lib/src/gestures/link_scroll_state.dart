import 'package:clean_tab_view/src/gestures/link_controller.dart';
import 'package:clean_tab_view/src/gestures/sync_controller.dart';
import 'package:clean_tab_view/src/gestures/sync_scroll_state.dart';
import 'package:flutter/widgets.dart';

abstract class LinkScrollState<T extends StatefulWidget>
    extends SyncScrollState<T> {
  LinkScrollControllerMixin get linkScrollController;

  @override
  SyncScrollControllerMixin get syncScrollController => linkScrollController;

  bool get link;

  @override
  @mustCallSuper
  void didChangeDependencies() {
    linkParent();

    super.didChangeDependencies();
  }

  @override
  @mustCallSuper
  void didUpdateWidget(covariant T oldWidget) {
    linkParent();

    super.didUpdateWidget(oldWidget);
  }

  @mustCallSuper
  // ignore: avoid_shadowing_type_parameters
  void linkParent<S extends StatefulWidget, T extends LinkScrollState<S>>() {
    linkScrollController.unlinkParent();

    if (link) {
      linkScrollController.linkParent<S, T>(context);
    }
  }

  @override
  void handleDragUpdate(DragUpdateDetails details) {
    _handleParentController(details);

    super.handleDragUpdate(details);
  }

  void _handleParentController(DragUpdateDetails details) {
    if (linkScrollController.parentIsNotNull) {
      final double delta = scrollDirection == Axis.horizontal
          ? details.delta.dx
          : details.delta.dy;

      linkScrollController.linkActivedParent(
        delta,
        details,
        textDirection ?? TextDirection.ltr,
      );
    }
  }
}
