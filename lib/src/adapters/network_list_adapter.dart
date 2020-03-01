import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import 'package:http/io_client.dart';

import 'list_adapter.dart';

class NetworkListAdapter implements BaseListAdapter {
  final BaseClient client;
  final String url;
  final String limitParam;
  final String offsetParam;
  final Map<String, String> headers;

  const NetworkListAdapter({
    @required this.url,
    @required this.limitParam,
    @required this.offsetParam,
    this.client,
    this.headers,
  })  : assert(url != null),
        assert(limitParam != null),
        assert(offsetParam != null);

  Future<T> _withClient<T>(Future<T> Function(BaseClient client) fn) async {
    if (client != null) {
      return await fn(client);
    } else {
      var _client = IOClient();
      try {
        return await fn(_client);
      } finally {
        _client.close();
      }
    }
  }

  @override
  Future<ListItems> getItems(int offset, int limit) async {
    var finalUrl = '$url${url.contains('?') ? '&' : '?'}$offsetParam='
        '${offset.toString()}&$limitParam=${limit.toString()}';

    var response = await _withClient((client) {
      return client.get(finalUrl, headers: headers);
    });

    if (response.statusCode < 300) {
      Iterable items = json.decode(utf8.decode(response.bodyBytes));
      return ListItems(items, reachedToEnd: items.length == 0);
    } else {
      throw ClientException('HTTP ${response.statusCode}: Failed to fetch');
    }
  }
}
