import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

class ListItems {
  final Iterable items;
  final bool reachedToEnd;

  ListItems(this.items, {this.reachedToEnd = false});
}

mixin BaseListAdapter<T> {
  Future<ListItems> getItems(int offset, int limit);
  bool shouldUpdate(covariant BaseListAdapter<T> old);
}

class ListAdapter implements BaseListAdapter {
  final Future<ListItems> Function(int offset, int limit) fetchItems;

  ListAdapter({@required this.fetchItems}) : assert(fetchItems != null);

  @override
  Future<ListItems> getItems(int offset, int limit) {
    return fetchItems(offset, limit);
  }

  @override
  bool shouldUpdate(ListAdapter old) => fetchItems != old.fetchItems;
}
