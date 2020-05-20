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
  final bool disablePagination;
  final Map<String, String> headers;

  const NetworkListAdapter({
    @required this.url,
    this.limitParam,
    this.offsetParam,
    this.disablePagination = false,
    this.client,
    this.headers,
  })  : assert(url != null),
        assert(disablePagination == true || limitParam != null),
        assert(disablePagination == true || offsetParam != null);

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
    var finalUrl = disablePagination != true
        ? _generateUrl(url, {offsetParam: offset, limitParam: limit})
        : url;

    var response = await _withClient((client) {
      return client.get(finalUrl, headers: headers);
    });

    if (response.statusCode < 300) {
      Iterable items = json.decode(utf8.decode(response.bodyBytes));
      return ListItems(
        items,
        reachedToEnd: disablePagination == true || items.length == 0,
      );
    } else {
      throw ClientException('HTTP ${response.statusCode}: Failed to fetch');
    }
  }

  @override
  bool shouldUpdate(NetworkListAdapter old) =>
      (limitParam != old.limitParam) ||
      (disablePagination != old.disablePagination) ||
      (client != old.client) ||
      (headers != old.headers) ||
      (offsetParam != old.offsetParam) ||
      (url != old.url);
}

String _generateUrl(String url, Map<String, dynamic> params) {
  url += url.contains('?') ? '&' : '?';
  params.forEach((key, value) {
    url += '$key=${Uri.encodeComponent(value.toString())}&';
  });

  if (url.endsWith('&')) url = url.substring(0, url.length - 1);

  return url;
}