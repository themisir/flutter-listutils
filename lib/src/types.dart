import 'package:flutter/widgets.dart';

import 'custom_list_view.dart';

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
  dynamic error,
  CustomListViewState listViewState,
);