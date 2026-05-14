import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'api_client.dart';
import 'api_exception.dart';

class HttpApiClient implements ApiClient {
  HttpApiClient({
    required AppConfig config,
    http.Client? httpClient,
  })  : _config = config,
        _httpClient = httpClient ?? http.Client();

  final AppConfig _config;
  final http.Client _httpClient;

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, String>? queryParameters,
  }) async {
    final response = await _httpClient.get(
      _uriFor(path, queryParameters: queryParameters),
      headers: _headers(),
    );
    return _decodeObject(response);
  }

  @override
  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final response = await _httpClient.post(
      _uriFor(path),
      headers: _headers(),
      body: jsonEncode(body ?? const <String, dynamic>{}),
    );
    return _decodeObject(response);
  }

  @override
  Future<Map<String, dynamic>> putJson(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final response = await _httpClient.put(
      _uriFor(path),
      headers: _headers(),
      body: jsonEncode(body ?? const <String, dynamic>{}),
    );
    return _decodeObject(response);
  }

  @override
  Future<void> delete(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final response = await _httpClient.delete(
      _uriFor(path),
      headers: _headers(),
      body: body == null ? null : jsonEncode(body),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        message: response.body.isEmpty ? 'Request failed' : response.body,
        statusCode: response.statusCode,
      );
    }
  }

  Uri _uriFor(
    String path, {
    Map<String, String>? queryParameters,
  }) {
    final base = Uri.parse(_config.apiBaseUrl);
    return base.replace(
      path: '${base.path}${path.startsWith('/') ? path : '/$path'}',
      queryParameters: queryParameters,
    );
  }

  Map<String, String> _headers() {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    final token = _config.apiBearerToken.trim();
    if (token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  Map<String, dynamic> _decodeObject(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        message: response.body.isEmpty ? 'Request failed' : response.body,
        statusCode: response.statusCode,
      );
    }

    if (response.body.isEmpty) {
      return const <String, dynamic>{};
    }

    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    throw const ApiException(message: 'Expected a JSON object response');
  }
}
