import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'adapters/list_adapter.dart';
import 'types.dart';

class CustomListView extends StatefulWidget {
  const CustomListView({
    Key key,
    this.pageSize = 30,
    this.header,
    this.footer,
    this.empty,
    this.adapter,
    @required this.itemBuilder,
    this.loadingBuilder,
    this.separatorBuilder,
    this.errorBuilder,
    this.padding,
    this.physics,
    this.itemCount,
    this.onLoadMore,
    this.onRefresh,
    this.disableRefresh = false,
    this.scrollDirection = Axis.vertical,
    this.shrinkWrap = false,
    this.debounceDuration = const Duration(milliseconds: 500),
  })  : assert(itemBuilder != null),
        assert(adapter != null || itemCount != null),
        assert(debounceDuration != null),
        super(key: key);

  /// Item count to request on each time list is scrolled to the end
  final int pageSize;

  /// Widget to be be displayed on the top of other items
  final Widget header;

  /// Widget that displayed after all of the items
  final Widget footer;

  /// Widget that's displayed if no item is available to display
  final Widget empty;

  /// List adapter used to fetch items dynamically
  final BaseListAdapter adapter;

  /// Loading widget builder, displayed when data is fetching from [adapter] or
  /// [onLoadMore] is called
  final WidgetBuilder loadingBuilder;

  /// Same as flutter's [ListView.builder] itemBuilder
  final ItemBuilder itemBuilder;

  /// Same as flutter's [ListView.separated] separatorBuilder
  final SeparatorBuilder separatorBuilder;

  /// Builds widget when loading failed
  final LoadErrorBuilder errorBuilder;

  /// Called when refresh is triggered, default behaviour is to set offset to
  /// zero and re-load entries from [adapter]
  final AsyncCallback onRefresh;

  /// Called when list is scrolled to the end
  final AsyncCallback onLoadMore;

  /// Set true if you would like to disable pull to refres
  /// gesture
  final bool disableRefresh;

  /// Edge padding
  final EdgeInsets padding;

  /// Scroll physics
  final ScrollPhysics physics;

  /// Set this to use this widget like [ListView.builder]
  final int itemCount;

  /// Scroll direction
  final Axis scrollDirection;

  /// TODO: Add description
  final bool shrinkWrap;

  /// Debounce duration to throttle load requests
  final Duration debounceDuration;

  @override
  CustomListViewState createState() => CustomListViewState();
}

class CustomListViewState extends State<CustomListView> {
  List items = [];
  Future future;
  bool reachedToEnd = false;

  bool _loading = false;
  bool _fetching = false;
  LoadErrorDetails _errorDetails;
  Timer _loadDebounce;

  bool get loading => _loading;
  bool get fetching => _fetching;

  @override
  void initState() {
    super.initState();
    loadMore();
  }

  Future fetchFromAdapter({int offset, bool merge = true}) async {
    if (_fetching) return;

    _fetching = true;

    try {
      var skip = offset ?? items?.length ?? 0;
      var result = await widget.adapter.getItems(skip, widget.pageSize);

      if (mounted) {
        setState(() {
          reachedToEnd = result.reachedToEnd ?? false;
          if (merge) {
            items.addAll(result.items);
          } else {
            items = result.items.toList();
          }
        });
      }
    } finally {
      _fetching = false;
    }
  }

  Future reload() async {
    future = null;
    await fetchFromAdapter(offset: 0, merge: false);
  }

  Future refresh() async {
    if (widget.onRefresh != null) {
      return widget.onRefresh();
    } else if (widget.adapter != null) {
      return reload();
    }
  }

  Future loadMore() async {
    if (reachedToEnd || _loading) return;
    if (widget.adapter == null && widget.onLoadMore == null) return;
    if (_loadDebounce?.isActive ?? false) _loadDebounce.cancel();

    _loadDebounce = Timer(widget.debounceDuration, () async {
      _loading = true;

      try {
        if (widget.adapter != null) {
          this.future = fetchFromAdapter();
        } else {
          this.future = widget.onLoadMore();
        }

        setState(() {});

        await future;
      } catch (e, stack) {
        if (mounted) {
          setState(() {
            _errorDetails = LoadErrorDetails(e, stackTrace: stack);
          });
        }
      } finally {
        _loading = false;
      }
    });
  }

  // ignore: missing_return
  bool handleScrollNotification(ScrollNotification notification) {
    if (notification.depth > 0) return false;
    if (notification.metrics.pixels == notification.metrics.maxScrollExtent) {
      loadMore();
    }
  }

  int get itemCount {
    return widget.itemCount ?? items.length;
  }

  Widget buildItem(BuildContext context, int index) {
    if (widget.header != null) {
      if (index == 0) return widget.header;
      index--;
    }

    if (index < itemCount) {
      return widget.itemBuilder(
        context,
        index,
        widget.adapter != null ? items[index] : null,
      );
    }

    if (widget.empty != null) {
      if (index == itemCount) {
        if (itemCount == 0) {
          return widget.empty;
        } else {
          return Container();
        }
      }
      index--;
    }

    if (widget.loadingBuilder != null || widget.errorBuilder != null) {
      if (index == itemCount) {
        return Consumer<Future>(
          builder: (context, future, _) {
            return FutureBuilder(
              future: future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return widget.loadingBuilder(context);
                } else if (widget.errorBuilder != null) {
                  return Consumer<LoadErrorDetails>(
                    builder: (context, details, _) {
                      if (details == null) {
                        return Container();
                      } else {
                        return widget.errorBuilder(context, details, this);
                      }
                    },
                  );
                } else {
                  return Container();
                }
              },
            );
          },
        );
      }
      index--;
    }

    if (widget.footer != null) {
      if (index == itemCount) return widget.footer;
      index--;
    }

    throw Exception('Failed to render list item, the index is out of bounds.');
  }

  Widget buildList(BuildContext context) {
    int count = itemCount +
        (widget.header != null ? 1 : 0) +
        (widget.footer != null ? 1 : 0) +
        ((widget.loadingBuilder != null || widget.errorBuilder != null)
            ? 1
            : 0) +
        (widget.empty != null ? 1 : 0);

    if (widget.separatorBuilder == null) {
      return ListView.builder(
        padding: widget.padding,
        physics: widget.physics,
        scrollDirection: widget.scrollDirection,
        shrinkWrap: widget.shrinkWrap,
        itemBuilder: buildItem,
        itemCount: count,
      );
    }

    return ListView.separated(
      padding: widget.padding,
      physics: widget.physics,
      scrollDirection: widget.scrollDirection,
      shrinkWrap: widget.shrinkWrap,
      itemBuilder: buildItem,
      separatorBuilder: widget.separatorBuilder,
      itemCount: count,
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget notificationListener = NotificationListener<ScrollNotification>(
      onNotification: handleScrollNotification,
      child: buildList(context),
    );
    Widget content = widget.disableRefresh
        ? notificationListener
        : RefreshIndicator(
            onRefresh: refresh,
            child: notificationListener,
          );

    return Provider<Future>.value(
      value: future,
      child: Provider<LoadErrorDetails>.value(
        value: _errorDetails,
        child: content,
      ),
    );
  }
}
