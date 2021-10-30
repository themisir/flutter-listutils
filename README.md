> ### PLEASE READ BEFORE USING
> This and similar widgets will going to help you build up your projects without spending too much time
> on developing proper state management solution. But doing so will lead to maintainance related issues
> in future because you lost control over how the app state is managed. When I made this code which was
> previously part of my own project I thought it would be cool to have something that manages entire
> state for lists from failure, retry to pagination. But as it turned out combining all of that logic
> into one widget was not a great thing because as project grows up, you'll realize that using conventional
> methods for state managed no longer works out, so you decide to migrate to other state management solutions
> like bloc, riverpod or custom built ones. And when you do so, this kind of widgets that helps you
> by managing large portion of state management for you doesn't works well with other parts of your app so
> you will have to write that parts from scratch to adopt new design decisions.
> 
> ### Conclusion
> I would not recommend using this or similar pagination managing widgets for handing everything for you.
> Instead learn and use a proper state management solution and use it to clean up your code.

# 📜 listview_utils

[![pub package](https://img.shields.io/pub/v/listview_utils.svg)](https://pub.dev/packages/listview_utils)
[![GitHub](https://img.shields.io/github/license/TheMisir/flutter-listutils)](https://github.com/TheMisir/flutter-listutils/blob/master/LICENSE)
![Platform](https://img.shields.io/badge/platform-web%20%7C%20android%20%7C%20ios-ff69b4)

Superchange `ListView` with custom adapters to add infinite scrolling.

## Maintenance status

Due to lack of my time and interest in this project my (@themisir's) availability
I would no long able to spend time on implementing new features. So this project
is kind of in "stalled" but I can provide maintainance if there's some critical
bugs or code-breaking stuff. So feel free to create an issue to report any important
stuff that breaks your workflow if you're using this package.

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
  
  //Pagination Mode [offset/page] (default: offset)
  paginationMode: PaginationMode.offset 
  
  //Initial offset (default: 0)
  initialOffset: 0
  


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

## Controllers
### Scroll controller
ListView Utils supports Flutter's built-in [`ScrollController`](https://api.flutter.dev/flutter/widgets/ScrollController-class.html),
which allows for controlling the scrolling position:

```dart
class _SomeWidgetState extends State<SomeWidget> {
  ScrollController scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FlatButton(
          onPressed: () {
            scrollController.animateTo(100);
          },
          child: const Text('Scroll down'),
        ),
        Expanded(
          child: CustomListView(
            adapter: ...,
            scrollController: scrollController,
            itemBuilder: (context, index, dynamic item) {
              return ListTile(
                title: Text(item['title']),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }
}
```

### List controller
ListView Utils also supports its own custom controller, which allows for controlling the list of items
(for example, programmatically refreshing the list):

```dart
class _SomeWidgetState extends State<SomeWidget> {
  CustomListViewController listViewController = CustomListViewController();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FlatButton(
          onPressed: () {
            listViewController.refresh();
          },
          child: const Text('Refresh'),
        ),
        Expanded(
          child: CustomListView(
            adapter: ...,
            loadingBuilder: (context) => const Center(
              child: CircularProgressIndicator(),
            ),
            scrollController: scrollController,
            itemBuilder: (context, index, dynamic item) {
              return ListTile(
                title: Text(item['title']),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    listViewController.dispose();
    super.dispose();
  }
}
```

