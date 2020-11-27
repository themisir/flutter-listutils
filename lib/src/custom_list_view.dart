import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../listview_utils.dart';
import 'adapters/list_adapter.dart';
import 'controller.dart';
import 'types.dart';

enum PaginationMode {
  /// Offset increases by item count
  ///
  /// Example:
  /// items?_offset=0
  /// items?_offset=10
  offset,

  /// Offset increases by +1
  ///
  /// Example:
  /// items?_offset=1
  /// items?_offset=2
  page
}

class CustomListView<T> extends StatefulWidget {
  const CustomListView({
    Key key,
    this.paginationMode = PaginationMode.offset,
    this.pageSize = 30,
    this.initialOffset = 0,
    this.header,
    this.footer,
    this.empty = const SizedBox(),
    this.adapter,
    @required this.itemBuilder,
    this.loadingBuilder,
    this.separatorBuilder,
    this.errorBuilder,
    this.padding = EdgeInsets.zero,
    this.physics,
    this.itemCount,
    this.onRefresh,
    this.disableRefresh = false,
    this.scrollDirection = Axis.vertical,
    this.shrinkWrap = false,
    this.debounceDuration = const Duration(milliseconds: 500),
    double itemExtend,
    this.distanceToLoadMore = 200,
    this.listViewController,
    this.scrollController,
    this.controller,
  })  : assert(itemBuilder != null),
        assert(adapter != null || itemCount != null),
        assert(debounceDuration != null),
        assert(distanceToLoadMore != null),
        assert(paginationMode != null),
        assert(initialOffset != null),
        assert(controller == null || scrollController == null),
        this.itemExtend = separatorBuilder == null ? itemExtend : null,
        super(key: key);

  /// Pagination mode (offset / page)
  final PaginationMode paginationMode;

  /// Item count to request on each time list is scrolled to the end
  final int pageSize;

  /// Initial offset value
  final int initialOffset;

  /// Widget to be be displayed on the top of other items
  final Widget header;

  /// Widget that displayed after all of the items
  final Widget footer;

  /// Widget that's displayed if no item is available to display
  final Widget empty;

  /// List adapter used to fetch items dynamically
  final BaseListAdapter<T> adapter;

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

  /// Set true if you would like to disable pull to refresh
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

  /// Whether the extent of the scroll view in the [scrollDirection] should be
  /// determined by the contents being viewed.
  final bool shrinkWrap;

  /// Debounce duration to throttle load requests
  final Duration debounceDuration;

  /// Item height
  final double itemExtend;

  /// Scroll distance to the end in pixels required to load more
  final double distanceToLoadMore;

  /// The list view controller
  final CustomListViewController listViewController;

  /// Scroll controller
  final ScrollController scrollController;

  @Deprecated(
      'The controller property has been deprecated. Use scrollController instead.')
  final ScrollController controller;

  @override
  CustomListViewState createState() => CustomListViewState();
}

enum _CLVStatus { idle, loading, error }

class _CLVState {
  const _CLVState(this.status, [this.error]);

  static const idle = const _CLVState(_CLVStatus.idle);
  static const loading = const _CLVState(_CLVStatus.loading);

  static _CLVState createError(dynamic e) => _CLVState(_CLVStatus.error, e);

  final _CLVStatus status;
  final dynamic error;
}

class CustomListViewState extends State<CustomListView> {
  final _stateNotifier = ValueNotifier<_CLVState>(_CLVState.loading);
  final List items = [];

  int _offset = 0;
  bool _reachedToEnd = false;
  bool _loading = false;
  bool _fetching = false;
  Timer _loadDebounce;

  bool get loading => _loading;
  bool get fetching => _fetching;
  bool get reachedToEnd => _reachedToEnd;
  int get offset => _offset;

  @override
  void initState() {
    super.initState();

    _offset = widget.initialOffset;

    if (!loadMore(offset: widget.initialOffset)) {
      _stateNotifier.value = _CLVState.idle;
    }

    if (widget.listViewController != null) {
      widget.listViewController.attach(this);
    }
  }

  @override
  void dispose() {
    _stateNotifier.dispose();
    super.dispose();
  }

  Future fetchFromAdapter({int offset, bool merge = true}) async {
    if (_fetching) {
      return;
    } else {
      _fetching = true;
    }

    switch (widget.paginationMode) {
      case PaginationMode.offset:
        _offset = offset ?? items?.length ?? _offset;
        break;

      case PaginationMode.page:
        _offset = offset ?? (_offset + 1);
        break;
    }

    try {
      var result = await widget.adapter.getItems(_offset, widget.pageSize);

      if (mounted) {
        setState(() {
          _reachedToEnd = result.reachedToEnd ?? false;
          if (merge != true) {
            items.clear();
          }
          items.addAll(result.items);
        });
      }
    } finally {
      _fetching = false;
    }
  }

  /// Clears [items] and loads data from adapter.
  Future reload() =>
      fetchFromAdapter(offset: widget.initialOffset, merge: false);

  Future refresh() async {
    if (widget.onRefresh != null) {
      return widget.onRefresh();
    } else if (widget.adapter != null) {
      return reload();
    }
  }

  /// Like [refresh], but shows the loading indicator and the error state
  Future refreshWithIndicator() async {
    assert(widget.onRefresh != null || widget.adapter != null);

    if (_loadDebounce?.isActive ?? false) _loadDebounce.cancel();

    setState(() => items.clear());
    _loading = true;
    _stateNotifier.value = _CLVState.loading;

    try {
      if (widget.onRefresh != null) {
        await widget.onRefresh();
      } else if (widget.adapter != null) {
        await reload();
      }
      _stateNotifier.value = _CLVState.idle;
    } catch (e) {
      _stateNotifier.value = _CLVState.createError(e);
    } finally {
      _loading = false;
    }
  }

  /// Returns true if loading was triggered, or false if loading is not
  /// triggered because of might be already loading or there is not a source for
  /// loading data from.
  bool loadMore({int offset}) {
    if (_reachedToEnd || _loading || widget.adapter == null) return false;
    if (_loadDebounce?.isActive ?? false) _loadDebounce.cancel();

    _loadDebounce = Timer(widget.debounceDuration, () async {
      _loading = true;
      _stateNotifier.value = _CLVState.loading;

      try {
        await fetchFromAdapter(offset: offset);
        _stateNotifier.value = _CLVState.idle;
      } catch (e) {
        _stateNotifier.value = _CLVState.createError(e);
      } finally {
        _loading = false;
      }
    });

    return true;
  }

  /// Returns item count
  int get itemCount => widget.itemCount ?? items.length;

  EdgeInsets _calculatePadding({bool first, bool last}) {
    EdgeInsets padding = widget.padding;
    if (widget.scrollDirection == Axis.vertical) {
      if (first != true) {
        padding = padding.copyWith(top: 0);
      }
      if (last != true) {
        padding = padding.copyWith(bottom: 0);
      }
    } else {
      if (first != true) {
        padding = padding.copyWith(left: 0);
      }
      if (last != true) {
        padding = padding.copyWith(right: 0);
      }
    }
    return padding;
  }

  SliverChildDelegate _buildDelegate() {
    int realItemCount = itemCount;

    if (widget.separatorBuilder != null) {
      realItemCount = max(realItemCount * 2 - 1, 0);
    }

    return SliverChildBuilderDelegate(
      (context, int index) {
        if (widget.separatorBuilder != null) {
          if (index.isOdd) {
            return widget.separatorBuilder(context, index ~/ 2);
          } else {
            index = index ~/ 2;
          }
        }

        return widget.itemBuilder(
          context,
          index,
          widget.adapter != null ? items[index] : null,
        );
      },
      semanticIndexCallback: (_, int index) {
        if (widget.separatorBuilder != null) {
          return index ~/ 2;
        } else {
          return index;
        }
      },
      childCount: realItemCount,
    );
  }

  Widget _buildList(BuildContext context) {
    final Widget stateWidget = ValueListenableBuilder<_CLVState>(
      valueListenable: _stateNotifier,
      builder: (context, state, _) {
        if (state.status == _CLVStatus.loading &&
            widget.loadingBuilder != null) {
          return widget.loadingBuilder(context);
        } else if (state.status == _CLVStatus.error &&
            widget.errorBuilder != null) {
          return widget.errorBuilder(context, state.error, this);
        } else if (itemCount == 0) {
          return widget.empty;
        } else {
          return SizedBox();
        }
      },
    );

    final SliverChildDelegate delegate = _buildDelegate();
    final Widget children =
        (widget.separatorBuilder == null && widget.itemExtend != null)
            ? SliverFixedExtentList(
                delegate: delegate,
                itemExtent: widget.itemExtend,
              )
            : SliverList(delegate: delegate);

    final List<Widget> slivers = <Widget>[
      if (widget.header != null) SliverToBoxAdapter(child: widget.header),
      children,
      SliverToBoxAdapter(child: stateWidget),
      if (widget.footer != null) SliverToBoxAdapter(child: widget.footer),
    ];

    int i = 0;

    return CustomScrollView(
      scrollDirection: widget.scrollDirection,
      shrinkWrap: widget.shrinkWrap,
      semanticChildCount: itemCount,
      controller: widget.scrollController ?? widget.controller,
      physics: widget.physics,
      slivers: slivers.map((sliver) {
        int index = i++;
        return SliverPadding(
          sliver: sliver,
          padding: _calculatePadding(
            first: index == 0,
            last: index == slivers.length,
          ),
        );
      }).toList(),
    );
  }

  @override
  void didUpdateWidget(CustomListView old) {
    super.didUpdateWidget(old);
    if (old.listViewController != widget.listViewController &&
        widget.listViewController != null) {
      widget.listViewController.attach(this);
    }

    if (old.adapter != widget.adapter) {
      if (old.adapter != null && widget.adapter != null) {
        if (old.adapter.shouldUpdate(widget.adapter) == false) {
          return;
        }
      }
      reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget child = PaginationListener(
      onNextPage: loadMore,
      distance: widget.distanceToLoadMore,
      child: _buildList(context),
    );

    if (widget.disableRefresh) {
      return child;
    }

    return RefreshIndicator(
      onRefresh: refresh,
      child: child,
    );
  }
}
