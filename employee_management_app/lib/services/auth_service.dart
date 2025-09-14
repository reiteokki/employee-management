import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _tokenKey = "access_token";
  static const String _refreshTokenKey = "refresh_token";
  static const String _userIdKey = "user_id";

  static String get baseUrl {
    String url = dotenv.env['API_URL'] ?? "";
    if (Platform.isAndroid) {
      url = url.replaceFirst("localhost", "10.0.2.2");
    }
    return url;
  }

  static Future<String?> login(String mRepId, String password) async {
    final url = Uri.parse("$baseUrl/auth/login");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"m_rep_id": mRepId, "password": password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data["token"];
      final refreshToken = data["refreshToken"];
      final user = data["user"];

      if (token != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, token);
        await prefs.setString(_refreshTokenKey, refreshToken);
        await prefs.setString(_userIdKey, user?["m_rep_id"]?.toString() ?? mRepId);
        return token;
      }
    }
    return null;
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }

  static Future<String?> refreshAccessToken() async {
    final refreshToken = await getRefreshToken();
    if (refreshToken == null) return null;

    final url = Uri.parse("$baseUrl/auth/refresh");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"refreshToken": refreshToken}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final newToken = data["token"];
      if (newToken != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, newToken);
        return newToken;
      }
    }
    return null;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userIdKey);
  }
}
