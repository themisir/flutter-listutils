import 'package:flutter/widgets.dart';

typedef ItemBuilder = Widget Function(BuildContext context, int index, dynamic item);
typedef SeparatorBuilder = Widget Function(BuildContext, int);