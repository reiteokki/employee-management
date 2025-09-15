import 'dart:convert';
import 'dart:io';
import 'package:employee_management_app/models/auth_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _tokenKey = "access_token";
  static const String _refreshTokenKey = "refresh_token";
  static const String _userIdKey = "user_id";
  static const String _userRoleKey = "user_role";

  static const Map<String, String> _jsonHeaders = {
    "Content-Type": "application/json",
  };

  static String get baseUrl {
    String url = dotenv.env['API_URL'] ?? "";
    if (Platform.isAndroid) {
      url = url.replaceFirst("localhost", "10.0.2.2");
    }
    return url;
  }

  static Future<String?> login(String mRepId, String password) async {
    try {
      final url = Uri.parse("$baseUrl/auth/login");
      final response = await http.post(
        url,
        headers: _jsonHeaders,
        body: jsonEncode({"m_rep_id": mRepId, "password": password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final auth = AuthModel.fromJson(data);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, auth.token);
        await prefs.setString(_refreshTokenKey, auth.refreshToken);
        await prefs.setString(_userIdKey, auth.user.mRepId);
        await prefs.setString(_userRoleKey, auth.user.role);

        return auth.token;
      } else {
        debugPrint("Login failed: ${response.body}");
      }
    } catch (e) {
      debugPrint("Login error: $e");
    }
    return null;
  }

  static Future<String?> getToken() async =>
      (await SharedPreferences.getInstance()).getString(_tokenKey);

  static Future<String?> getRefreshToken() async =>
      (await SharedPreferences.getInstance()).getString(_refreshTokenKey);

  static Future<String?> getUserId() async =>
      (await SharedPreferences.getInstance()).getString(_userIdKey);

  static Future<String?> getUserRole() async =>
      (await SharedPreferences.getInstance()).getString(_userRoleKey);

  static Future<bool> isLoggedIn() async => (await getToken()) != null;

  static Future<String?> refreshAccessToken() async {
    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null) return null;

      final url = Uri.parse("$baseUrl/auth/refresh");
      final response = await http.post(
        url,
        headers: _jsonHeaders,
        body: jsonEncode({"refreshToken": refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newToken = data["token"] as String?;
        if (newToken != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_tokenKey, newToken);
          return newToken;
        }
      } else {
        debugPrint("Refresh token failed: ${response.body}");
      }
    } catch (e) {
      debugPrint("Refresh token error: $e");
    }
    return null;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_userRoleKey);
  }
}
