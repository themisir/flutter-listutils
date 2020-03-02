# 📃 ListView Utils

Additional utils for flutter `ListView` component.

## 🌟 Getting Started

Add those lines to `pubspec.yaml` file and run `flutter pub get`.

```yaml
dependencies:
  listview_utils: ^0.1.5
```

Check out [Installing](https://pub.dev/packages/listview_utils#-installing-tab-) tab for more details.

Import **listview_utils** package to your application by adding this line:

```dart
import 'package:listview_utils/listview_utils.dart';
```

This will import required classes to use **listview_utils**.

## ⚙ Properties

```dart
CustomListView( 
  // Items fetched per request (default: 30)
  pageSize: 30,

  // Header widget (default: null)
  header: Container(...),

  // Footer widget (default: null)
  footer: Container(...),

  // The widget that displayed if the list is empty (default: null)
  empty: Text('List is empty'),

  // Item provider adapter (default: null)
  adapter: ListAdapter(
    fetchItems: (int offset, int limit) {
      return ListItems([ ... ]);
    },
  ),

  // A callback function to build list items (required)
  itemBuilder: (BuildContext context, int index, dynamic item) {
    // If items provided by adapter the `item` argument will be matching element
    return ListTile(
      title: Text(item['title']),
    );
  },

  // Callback function to build widget if exception occurs during fetching items
  errorBuilder: (BuildContext context, LoadErrorDetails details, CustomListViewState state) {
    return Column(
      children: <Widget>[
        Text(details.error.toString()),
        RaisedButton(
          onPressed: () => state.loadMore(),
          child: Text('Retry'),
        ),
      ],
    );
  },

  // Static list of items
  children: <Widget>[
    ...
  ],

  // Item count
  itemCount: 45,

  // A callback function called when required to load more items
  onLoadMore: () async {
    ...
  },

  // A callback function called when pull to refresh is triggered
  onRefresh: () async {
    ...
  },

  // Enable / disable pull to refresh (default: false)
  disableRefresh: false,
),
```

## 🔌 Adapters

ListView Utils currently only supports network adapter. Or you could write your own adapter by implementing `BaseListAdapter` mixin or using `ListAdapter` class.

Here's simple network adapter code using jsonplaceholder data.

```dart
NetworkListAdapter(
  url: 'https://jsonplaceholder.typicode.com/posts',
  limitParam: '_limit',
  offsetParam: '_start',
),
```

## 📝 Example

```dart
CustomListView(
  loadingBuilder: CustomListLoading.defaultBuilder,
  itemBuilder: (context, index, item) {
    return ListTile(
      title: Text(item['title']),
    );
  },
  adapter: NetworkListAdapter(
    url: 'https://jsonplaceholder.typicode.com/posts',
    limitParam: '_limit',
    offsetParam: '_start',
  ),
);
```
