import 'package:clean_tab_view/src/official/tab_controller.dart';

class ExtendedTabController extends TabController {
  bool jump = false;

  ExtendedTabController({
    super.initialIndex = 0,
    super.animationDuration,
    required super.length,
    required super.vsync,
  });
}
