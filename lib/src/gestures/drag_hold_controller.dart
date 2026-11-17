import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

class DragHoldController {
  final ScrollPosition position;
  Drag? _drag;

  ScrollHoldController? _hold;

  DragHoldController(this.position);

  void handleDragDown(DragDownDetails? details) {
    assert(_drag == null);
    assert(_hold == null);

    _hold = position.hold(_disposeHold);
  }

  void handleDragStart(DragStartDetails details) {
    assert(_drag == null);

    _drag = position.drag(details, _disposeDrag);

    assert(_drag != null);
    assert(_hold == null);
  }

  void handleDragUpdate(DragUpdateDetails details) {
    assert(_hold == null || _drag == null);

    _drag?.update(details);
  }

  void handleDragEnd(DragEndDetails details) {
    assert(_hold == null || _drag == null);

    _drag?.end(details);

    assert(_drag == null);
  }

  void handleDragCancel() {
    assert(_hold == null || _drag == null);

    _hold?.cancel();
    _drag?.cancel();

    assert(_hold == null);
    assert(_drag == null);
  }

  void _disposeHold() {
    _hold = null;
  }

  void _disposeDrag() {
    _drag = null;
  }

  void forceCancel() {
    _hold = null;
    _drag = null;
  }

  bool get hasDrag => _drag != null;

  bool get hasHold => _hold != null;

  double get extentAfter => position.extentAfter;

  double get extentBefore => position.extentBefore;
}
