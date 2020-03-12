import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'adapters/list_adapter.dart';
import 'types.dart';

class CustomListView extends StatefulWidget {
  final int pageSize;
  final Widget header;
  final Widget footer;
  final Widget empty;
  final BaseListAdapter adapter;
  final List<Widget> children;
  final WidgetBuilder loadingBuilder;
  final ItemBuilder itemBuilder;
  final SeparatorBuilder separatorBuilder;
  final LoadErrorBuilder errorBuilder;
  final AsyncCallback onRefresh;
  final AsyncCallback onLoadMore;
  final bool disableRefresh;
  final EdgeInsets padding;
  final ScrollPhysics physics;
  final int itemCount;
  final Axis scrollDirection;
  final bool shrinkWrap;
  final Duration debounceDuration;

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
    this.children,
    this.itemCount,
    this.onLoadMore,
    this.onRefresh,
    this.disableRefresh = false,
    this.scrollDirection = Axis.vertical,
    this.shrinkWrap = false,
    this.debounceDuration = const Duration(milliseconds: 500),
  })  : assert(children != null || itemBuilder != null),
        assert(children != null || adapter != null || itemCount != null),
        assert(debounceDuration != null),
        super(key: key);

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
    return widget.children?.length ?? widget.itemCount ?? items.length;
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
    if (widget.children != null && widget.separatorBuilder == null) {
      return ListView(
        padding: widget.padding,
        physics: widget.physics,
        scrollDirection: widget.scrollDirection,
        shrinkWrap: widget.shrinkWrap,
        children: <Widget>[
          if (widget.header != null) widget.header,
          ...widget.children,
          if (widget.footer != null) widget.footer
        ],
      );
    }

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
