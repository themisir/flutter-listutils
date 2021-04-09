import 'package:flutter/widgets.dart';

class PaginationListener extends StatelessWidget {
  const PaginationListener({
    Key? key,
    this.distance = 200,
    this.maxDepth = 0,
    required this.onNextPage,
    required this.child,
  }) : super(key: key);

  final VoidCallback onNextPage;
  final double distance;
  final int maxDepth;
  final Widget child;

  bool _onScroll(ScrollNotification notif) {
    var delta = notif.metrics.maxScrollExtent - notif.metrics.pixels;
    if (notif.depth <= maxDepth && delta < distance) {
      onNextPage();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: child,
    );
  }
}
