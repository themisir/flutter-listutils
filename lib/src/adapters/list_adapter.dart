library listutils;

class ListItems<T> {
  final Iterable<T> items;
  final bool reachedToEnd;

  ListItems(this.items, {this.reachedToEnd = false});
}

mixin ListAdapter<T> {
  Future<ListItems<T>> getItems(int offset, int limit);
}
