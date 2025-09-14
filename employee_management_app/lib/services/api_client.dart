import 'package:http/http.dart' as http;
import 'auth_service.dart';

class ApiClient {
  static Future<http.Response> get(Uri url) async {
    return _send(() async => http.get(url, headers: await _headers()));
  }

  static Future<http.Response> post(Uri url, {Object? body}) async {
    return _send(
      () async => http.post(url, headers: await _headers(), body: body),
    );
  }

  static Future<http.Response> put(Uri url, {Object? body}) async {
    return _send(
      () async => http.put(url, headers: await _headers(), body: body),
    );
  }

  static Future<http.Response> delete(Uri url) async {
    return _send(() async => http.delete(url, headers: await _headers()));
  }

  static Future<http.Response> _send(
    Future<http.Response> Function() requestFn,
  ) async {
    var response = await requestFn();

    if (response.statusCode == 401) {
      final newToken = await AuthService.refreshAccessToken();
      if (newToken != null) {
        response = await requestFn(); // retry
      }
    }

    return response;
  }

  static Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken();
    return {
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };
  }
}
