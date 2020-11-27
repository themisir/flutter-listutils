import '../listview_utils.dart';

class CustomListViewController {
  CustomListViewState _state;
  attach(CustomListViewState state) {
    _state = state;
  }

  _assertAttached() {
    assert(
      _state != null,
      "You need to pass the controller to CustomListView's"
      " listViewController argument",
    );
  }

  /// Reloads the data while showing the loading indicator.
  /// Uses the `onRefresh` callback if provided. Otherwise, clears items
  /// and reloads the data from adapter.
  Future refresh() async {
    _assertAttached();
    await _state.refreshWithIndicator();
  }

  /// Low-level reload - clears items and reloads the data from adapter,
  /// without showing indicators and without calling `onRefresh`.
  Future reloadFromAdapter() async {
    _assertAttached();
    await _state.reload();
  }

  /// Loads the next page of items, beginning from offset.
  /// Returns true if loading was triggered, or false if loading is not
  /// triggered because of might be already loading or there is not a source for
  /// loading data from.
  bool loadMore({int offset}) {
    _assertAttached();
    return _state.loadMore(offset: offset);
  }

  dispose() {
    _state = null;
  }
}
