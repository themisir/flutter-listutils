import 'dart:convert';
import 'package:http/http.dart';
import 'list_adapter.dart';

class NetworkListAdapter<T> implements BaseListAdapter<T> {
  final BaseClient? client;
  final String url;
  final String? limitParam;
  final String? offsetParam;

  final bool disablePagination;
  final Map<String, String>? headers;

  const NetworkListAdapter({
    required this.url,
    this.limitParam,
    this.offsetParam,
    this.disablePagination = false,
    this.client,
    this.headers,
  })  : assert(disablePagination == true || limitParam != null),
        assert(disablePagination == true || offsetParam != null);

  Future<T> _withClient<T>(Future<T> Function(BaseClient? client) fn) async {
    if (client != null) {
      return await fn(client);
    } else {
      final BaseClient client = Client() as BaseClient;
      try {
        return await fn(client);
      } finally {
        client.close();
      }
    }
  }

  @override
  Future<ListItems<T>> getItems(int offset, int limit) async {
    String urlString = disablePagination != true
        ? _generateUrl(url, {offsetParam: offset, limitParam: limit})
        : url;

    Response response;
    response = await _withClient((client) {
      return client!.get(Uri.parse(urlString), headers: headers);
    });
    if (response.statusCode < 300) {
      Iterable? items = json.decode(utf8.decode(response.bodyBytes));
      return ListItems(
        items as Iterable<T>?,
        reachedToEnd: disablePagination == true || items!.length == 0,
      );
    } else {
      throw ClientException('HTTP ${response.statusCode}: Failed to fetch');
    }
  }

  @override
  bool shouldUpdate(NetworkListAdapter<T> old) =>
      (limitParam != old.limitParam) ||
      (disablePagination != old.disablePagination) ||
      (client != old.client) ||
      (headers != old.headers) ||
      (offsetParam != old.offsetParam) ||
      (url != old.url);
}

///
///Generate full url by iterating over [url] to find path paramaters and then adding [params] to it
///returns: [url] as a [String]
String _generateUrl(String url, Map<String?, dynamic> params) {
  url += url.contains('?') ? '&' : '?';
  params.forEach((key, value) {
    url += '$key=${Uri.encodeComponent(value.toString())}&';
  });

  if (url.endsWith('&')) url = url.substring(0, url.length - 1);

  return url;
}
