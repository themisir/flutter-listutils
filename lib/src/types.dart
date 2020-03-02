import 'package:flutter/widgets.dart';

import 'custom_list_view.dart';

class LoadErrorDetails {
  final Object error;
  final StackTrace stackTrace;
  LoadErrorDetails(this.error, {this.stackTrace});
}

typedef ItemBuilder = Widget Function(
  BuildContext context,
  int index,
  dynamic item,
);
typedef SeparatorBuilder = Widget Function(
  BuildContext context,
  int index,
);
typedef LoadErrorBuilder = Widget Function(
  BuildContext context,
  LoadErrorDetails errorDetails,
  CustomListViewState listViewState,
);
