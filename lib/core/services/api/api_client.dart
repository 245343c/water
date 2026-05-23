import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiClient {
  ApiClient._();

  static final ApiClient _instance = ApiClient._();
  static ApiClient get instance => _instance;

  static const _tokenKey = 'auth_token';

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  Future<Map<String, String>> _headers({bool requireAuth = true}) async {
    final headers = <String, String>{
      HttpHeaders.contentTypeHeader: 'application/json',
      HttpHeaders.acceptHeader: 'application/json',
    };
    if (requireAuth) {
      final token = await getToken();
      if (token != null) {
        headers[HttpHeaders.authorizationHeader] = 'Bearer $token';
      }
    }
    return headers;
  }

  Uri _uri(String path, [Map<String, String>? queryParams]) {
    final base = Uri.parse(backendBaseUrl);
    return Uri(
      scheme: base.scheme,
      host: base.host,
      port: base.port,
      path: '${base.path}$path',
      queryParameters: queryParams,
    );
  }

  Map<String, dynamic> _parse(http.Response response) {
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }
    final message = body['message'] as String? ?? 'Request failed';
    throw ApiException(message, statusCode: response.statusCode);
  }

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? queryParams,
    bool requireAuth = true,
  }) async {
    final response = await http.get(
      _uri(path, queryParams),
      headers: await _headers(requireAuth: requireAuth),
    );
    return _parse(response);
  }

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body, {
    bool requireAuth = true,
  }) async {
    final response = await http.post(
      _uri(path),
      headers: await _headers(requireAuth: requireAuth),
      body: jsonEncode(body),
    );
    return _parse(response);
  }

  Future<Map<String, dynamic>> put(
    String path,
    Map<String, dynamic> body, {
    bool requireAuth = true,
  }) async {
    final response = await http.put(
      _uri(path),
      headers: await _headers(requireAuth: requireAuth),
      body: jsonEncode(body),
    );
    return _parse(response);
  }

  Future<Map<String, dynamic>> patch(
    String path,
    Map<String, dynamic> body, {
    bool requireAuth = true,
  }) async {
    final response = await http.patch(
      _uri(path),
      headers: await _headers(requireAuth: requireAuth),
      body: jsonEncode(body),
    );
    return _parse(response);
  }

  Future<Map<String, dynamic>> delete(
    String path, {
    bool requireAuth = true,
  }) async {
    final response = await http.delete(
      _uri(path),
      headers: await _headers(requireAuth: requireAuth),
    );
    return _parse(response);
  }
}
