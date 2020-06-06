# 📜 listview_utils

 [![pub package](https://img.shields.io/pub/v/listview_utils.svg)](https://pub.dev/packages/listview_utils)
 [![GitHub](https://img.shields.io/github/license/TheMisir/flutter-listutils)](https://github.com/TheMisir/flutter-listutils/blob/master/LICENSE)
 ![Platform](https://img.shields.io/badge/platform-web%20%7C%20android%20%7C%20ios-ff69b4)

Superchange `ListView` with custom adapters to add infinite scrolling.

## Migration guide from 0.1.X to 0.2.Y

### `children` property removed

If you want to use children property with `CustomListView`, I suggest you to use flutter's own `ListView` component instead. We wanted to focus on dynamic sources rather than static ones.

### `onErrorBuilder` property type changed

<table>
<tr><th>Old</th><th>New</th></tr>
<tr><td>
  
```dart
CustomListView(
  onErrorBuilder: (context, details, listView) {
    // Print throwed exception to console
    print(details.error);
  },
)
```
  
</td><td>

```dart
CustomListView(
  onErrorBuilder: (context, error, listView) {
    // Print throwed exception to console
    print(error);
  },
)
```
  
</td></tr>
</table>

### `onLoadMore` property deprecated

You need to convert custom data source handlers to list adapters. Here's simple example how to implement your own list adapter.

```dart
class MyListAdapter implements BaseListAdapter {
  const MyListAdapter(this.url);
  
  final String url;

  @override
  Future<ListItems> getItems(int offset, int limit) async {
    // To handle errors using `errorBuilder` you need to not use *try/catch* block.
    final response = await http.get(`url?_offset=$offset&_limit=$limit`);
    final data = jsonDecode(response.data);
    
    return ListItems(data, reachedToEnd: data.length == 0);
  }
  
  @override
  bool shouldUpdate(MyListAdapter old) {
    return old.url != url;
  }
}
```

## Getting Started

Add those lines to `pubspec.yaml` file and run `flutter pub get`.

```yaml
dependencies:
  listview_utils: ">=0.2.2 <2.0.0"
```

Check out [Installing](https://pub.dev/packages/listview_utils#-installing-tab-) tab for more details.

Import **listview_utils** package to your application by adding this line:

```dart
import 'package:listview_utils/listview_utils.dart';
```

This will import required classes to use **listview_utils**.

## Properties

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

  // Item count
  itemCount: 45,

  // A callback function called when pull to refresh is triggered
  onRefresh: () async {
    ...
  },

  // Enable / disable pull to refresh (default: false)
  disableRefresh: false,
),
```

## Adapters

ListView Utils currently only supports network adapter. Or you could write your own adapter by implementing `BaseListAdapter` mixin or using `ListAdapter` class.

Here's simple network adapter code using jsonplaceholder data.

```dart
NetworkListAdapter(
  url: 'https://jsonplaceholder.typicode.com/posts',
  limitParam: '_limit',
  offsetParam: '_start',
),
```

## Example

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
