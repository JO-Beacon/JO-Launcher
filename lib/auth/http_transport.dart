// Minimal HTTP wrapper for the authentication module.
//
// Desktop (Windows / Linux) can use `dart:io` HttpClient; no http package is
// needed. The interface exists so tests can feed fake responses without
// touching the network.

import 'dart:convert';
import 'dart:io';

class HttpResult {
  const HttpResult(this.statusCode, this.body);

  final int statusCode;
  final String body;

  bool get ok => statusCode >= 200 && statusCode < 300;
}

abstract class HttpTransport {
  Future<HttpResult> post(
    Uri url, {
    Map<String, String> headers = const <String, String>{},
    String? body,
  });

  Future<HttpResult> get(
    Uri url, {
    Map<String, String> headers = const <String, String>{},
  });
}

class IoHttpTransport implements HttpTransport {
  IoHttpTransport({this.timeout = const Duration(seconds: 20)});

  final Duration timeout;
  final HttpClient _client = HttpClient();

  @override
  Future<HttpResult> post(
    Uri url, {
    Map<String, String> headers = const <String, String>{},
    String? body,
  }) {
    return _send('POST', url, headers, body);
  }

  @override
  Future<HttpResult> get(
    Uri url, {
    Map<String, String> headers = const <String, String>{},
  }) {
    return _send('GET', url, headers, null);
  }

  Future<HttpResult> _send(
    String method,
    Uri url,
    Map<String, String> headers,
    String? body,
  ) async {
    _client.connectionTimeout = timeout;
    final HttpClientRequest request = await _client.openUrl(method, url);
    headers.forEach(request.headers.set);
    if (body != null) {
      request.add(utf8.encode(body));
    }
    final HttpClientResponse response = await request.close();
    final String text = await utf8.decodeStream(response);
    return HttpResult(response.statusCode, text);
  }
}
