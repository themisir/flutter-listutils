class ListItems<T> {
  final Iterable<T>? items;
  final bool reachedToEnd;

  const ListItems(this.items, {this.reachedToEnd = false});
}

mixin BaseListAdapter<T> {
  Future<ListItems<T>> getItems(int offset, int limit);
  bool shouldUpdate(covariant BaseListAdapter<T>? old);
}

class ListAdapter<T> implements BaseListAdapter<T> {
  final Future<ListItems<T>> Function(int offset, int limit) fetchItems;

  const ListAdapter({required this.fetchItems});

  @override
  Future<ListItems<T>> getItems(int offset, int limit) {
    return fetchItems(offset, limit);
  }

  @override
  bool shouldUpdate(ListAdapter<T> old) => fetchItems != old.fetchItems;
}
