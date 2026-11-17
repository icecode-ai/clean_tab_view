import 'package:clean_tab_view/src/gestures/gesture_state_mixin.dart';
import 'package:clean_tab_view/src/gestures/sync_controller.dart';
import 'package:flutter/widgets.dart';

abstract class SyncScrollState<T extends StatefulWidget>
    extends GestureStateMixin<T> {
  SyncScrollControllerMixin get syncScrollController;

  @override
  void handleDragDown(DragDownDetails details) {
    syncScrollController.forceCancel();
    syncScrollController.handleDragDown(details);
  }

  @override
  void handleDragStart(DragStartDetails details) {
    syncScrollController.handleDragStart(details);
  }

  @override
  void handleDragUpdate(DragUpdateDetails details) {
    syncScrollController.handleDragUpdate(details);
  }

  @override
  void handleDragEnd(DragEndDetails details) {
    syncScrollController.handleDragEnd(details);
  }

  @override
  void handleDragCancel() {
    syncScrollController.handleDragCancel();
  }

  @override
  void forceCancel() {
    syncScrollController.forceCancel();
  }
}
