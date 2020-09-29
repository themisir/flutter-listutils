import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'pagination_listener.dart';
import 'types.dart';

/// AdapterResult object that returned when loading next page.
class AdapterResult<T> {
  const AdapterResult(this.items, [this.reachedToEnd = false]);
  final List<T> items;
  final bool reachedToEnd;
}

typedef NextPageCallback<T> = Future<AdapterResult<T>> Function(int page);

/// Abstract adapter interface.
abstract class ListAdapter<T> {
  int get initialPage;
  Future<AdapterResult<T>> getPage(int page);

  factory ListAdapter({
    @required int initialPage,
    @required NextPageCallback onNext,
  }) =>
      _ListAdapter(initialPage: initialPage, onNext: onNext);
}

class _ListAdapter<T> implements ListAdapter<T> {
  const _ListAdapter({this.initialPage, this.onNext});

  @override
  final int initialPage;
  final NextPageCallback onNext;

  @override
  getPage(int page) => onNext(page);
}

typedef NextOffsetCallback<T> = Future<AdapterResult<T>> Function(
    int offset, int pageSize);

/// Abstrat adapter interface with offset & limit paging logic.
abstract class OffsetListAdapter<T> implements ListAdapter<T> {
  const OffsetListAdapter();
  factory OffsetListAdapter.create({
    @required NextOffsetCallback<T> onNext,
    @required int pageSize,
  }) =>
      _OffsetListAdapter<T>(onNext: onNext, pageSize: pageSize);

  int get pageSize;
  int get initialPage => 0;
  Future<AdapterResult<T>> getItems(int offset);

  @override
  @protected
  getPage(int page) => getItems(max(0, page - initialPage) * pageSize);
}

class _OffsetListAdapter<T> extends OffsetListAdapter<T> {
  const _OffsetListAdapter({this.pageSize, this.onNext}) : super();

  final int pageSize;
  final NextOffsetCallback<T> onNext;

  @override
  getItems(int offset) => onNext(offset, pageSize);
}

class CustomListView<T> extends StatefulWidget {
  const CustomListView({
    Key key,
    @required this.itemBuilder,
    this.header,
    this.footer,
    this.empty,
    this.adapter,
    this.loading,
    this.separatorBuilder,
    this.errorBuilder,
    this.physics,
    double itemExtend,
    this.shrinkWrap = false,
    this.padding = EdgeInsets.zero,
    this.disableRefresh = false,
    this.scrollDirection = Axis.vertical,
    this.distanceToLoadMore = 200,
    this.controller,
  })  : assert(itemBuilder != null),
        assert(adapter != null),
        assert(distanceToLoadMore != null),
        this.itemExtend = separatorBuilder == null ? itemExtend : null,
        super(key: key);

  /// Widget to be be displayed on the top of other items
  final Widget header;

  /// Widget that displayed after all of the items
  final Widget footer;

  /// Widget that's displayed if no item is available to display
  final Widget empty;

  /// List adapter used to fetch items dynamically
  final ListAdapter<T> adapter;

  /// Loading widget displayed when next page is loading
  final Widget loading;

  /// Same as flutter's [ListView.builder] itemBuilder
  final ItemBuilder itemBuilder;

  /// Same as flutter's [ListView.separated] separatorBuilder
  final SeparatorBuilder separatorBuilder;

  /// Builds widget when loading failed
  final Widget Function(BuildContext context, dynamic error) errorBuilder;

  /// Set true if you would like to disable pull to refres
  /// gesture
  final bool disableRefresh;

  /// Edge padding
  final EdgeInsets padding;

  /// Scroll physics
  final ScrollPhysics physics;

  /// Scroll direction
  final Axis scrollDirection;

  /// Whether the extent of the scroll view in the [scrollDirection] should be
  /// determined by the contents being viewed.
  final bool shrinkWrap;

  /// Item height
  final double itemExtend;

  /// Scroll distance to the end in pixels required to load more
  final double distanceToLoadMore;

  /// Scroll controller
  final ScrollController controller;

  @override
  _CustomListViewState createState() => _CustomListViewState();
}

class _CustomListViewState extends State<CustomListView> {
  final _showLoading = ValueNotifier(false);
  final _isEmpty = ValueNotifier(false);
  final _error = ValueNotifier(null);

  void loadNextPage() {}

  Future<void> refresh() async {}

  List<Widget> _buildContentSlivers(BuildContext context) {
    return <Widget>[
      // header
      if (widget.header != null) widget.header,

      // loading
      if (widget.loading != null)
        ValueListenableBuilder<bool>(
          valueListenable: _showLoading,
          builder: (context, value, child) =>
              value ? widget.loading : SizedBox(),
        ),

      // footer
      if (widget.footer != null) widget.footer,
    ];
  }

  List<Widget> _buildSingleChildSlivers(BuildContext context, Widget child) {
    return <Widget>[
      // header
      if (widget.header != null) widget.header,

      // child
      SliverFillRemaining(child: child),

      // footer
      if (widget.footer != null) widget.footer,
    ];
  }

  Widget buildScrollView(BuildContext context, List<Widget> slivers) {
    return PaginationListener(
      onNextPage: loadNextPage,
      distance: widget.distanceToLoadMore,
      child: CustomScrollView(
        physics: widget.physics,
        controller: widget.controller,
        shrinkWrap: widget.shrinkWrap,
        slivers: slivers,
      ),
    );
  }

  Widget build3(BuildContext context) {
    return buildScrollView(context, _buildContentSlivers(context));
  }

  Widget build2(BuildContext context) {
    if (widget.empty != null) {
      return ValueListenableBuilder<bool>(
        valueListenable: _isEmpty,
        builder: (context, value, child) => value
            ? buildScrollView(
                context,
                _buildSingleChildSlivers(context, widget.empty),
              )
            : build3(context),
      );
    } else {
      return build3(context);
    }
  }

  Widget build1(BuildContext context) {
    if (widget.errorBuilder != null) {
      return ValueListenableBuilder(
        valueListenable: _error,
        builder: (context, value, child) => value != null
            ? buildScrollView(
                context,
                _buildSingleChildSlivers(
                  context,
                  widget.errorBuilder(context, value),
                ),
              )
            : build2(context),
      );
    } else {
      return build2(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final child = build1(context);

    if (widget.disableRefresh) {
      return child;
    }

    return RefreshIndicator(child: child, onRefresh: refresh);
  }
}
