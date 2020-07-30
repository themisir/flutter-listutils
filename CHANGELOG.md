## [0.2.4] - 7/30/2020

* Storong type support

## [0.2.2] - 6/5/2020

* Added [`ScrollController`](https://api.flutter.dev/flutter/widgets/ScrollController-class.html) support

## [0.2.1] - 5/30/2020

* Added browser support to `NetworkListAdapter`

## [0.2.0] - 5/20/2020

* Removed `children` property from `CustomListView`
* Removed `provider` dependency
* `errorBuilder` method modified. Now accepts: `Widget Function(BuildContext context, dynamic error, CustomListViewState listView)`.
* `CustomListView` now using [`CustomScrollView`](https://api.flutter.dev/flutter/widgets/CustomScrollView-class.html) instead of `ListView`
* `onLoadMore` property is deprecated
* Fixed [#2](https://github.com/TheMisir/flutter-listutils/issues/2)

## [0.1.6+1] - 3/12/2020

* Fixed memory leak issue

## [0.1.6] - 3/5/2020

* Added `disablePagination` property to `NetworkListAdapter`

## [0.1.5] - 3/2/2020

* Added `errorBuilder` property to `CustomListView`
* Added `StaticListAdapter`
* Improved loading items using adapter by using debounce timer

## [0.1.4] - 3/2/2020

* Added `headers` property to `NetworkListAdapter`

## [0.1.3] - 3/2/2020

* Renamed from listutils to **listview_utils**
* Example code simplified

## [0.1.0] - 3/1/2020

* Fixed major bugs
* Added example project
* Readme created

## [0.0.2] - 3/1/2020

* Added description

## [0.0.1] - 3/1/2020

* Initial release
