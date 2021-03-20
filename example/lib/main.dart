import 'package:flutter/material.dart';
import 'package:listview_utils/listview_utils.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MaterialApp(
      title: 'Example',
      home: HomeScreen(),
    ),
  );
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('🔌 ListView_Utils')),
      body: SafeArea(
        child: CustomListView(
          paginationMode: PaginationMode.page,
          initialOffset: 0,
          loadingBuilder: CustomListLoading.defaultBuilder,
          header: Container(
            height: 50,
            child: Center(
              child: Text('😄 Header'),
            ),
          ),
          footer: Container(
            height: 50,
            child: Center(
              child: Text('🦶 Footer'),
            ),
          ),
          adapter: NetworkListAdapter(
            url: 'https://jsonplaceholder.typicode.com/posts',
            limitParam: '_limit',
            offsetParam: '_start',
          ),
          itemBuilder: (context, _, item) {
            return ListTile(
              title: Text(item['title']),
              leading: Icon(Icons.assignment),
            );
          },
          errorBuilder: (context, error, state) {
            return Column(
              children: <Widget>[
                Text(error.toString()),
                TextButton(
                  onPressed: () => state.loadMore(),
                  child: Text('Retry'),
                ),
              ],
            );
          },
          separatorBuilder: (context, _) {
            return Divider(height: 1);
          },
          empty: Center(
            child: Text('Empty'),
          ),
        ),
      ),
    );
  }
}
