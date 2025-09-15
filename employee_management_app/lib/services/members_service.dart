import 'dart:convert';
import 'dart:io';
import 'package:employee_management_app/services/api_client.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'auth_service.dart';

class MembersService {
  static String get baseUrl {
    String url = dotenv.env['API_URL'] ?? "";
    if (Platform.isAndroid) {
      url = url.replaceFirst("localhost", "10.0.2.2");
    }
    return url;
  }

  static Future<Map<String, dynamic>?> fetchProfile() async {
    try {
      final token = await AuthService.getToken();
      final userId = await AuthService.getUserId();

      if (token == null || userId == null) {
        throw Exception("User not logged in");
      }

      final uri = Uri.parse("${AuthService.baseUrl}/members/$userId");
      final res = await ApiClient.get(uri);

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      } else {
        throw Exception("Failed to load profile: ${res.body}");
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<List<dynamic>> getHierarchy() async {
    final url = Uri.parse("${AuthService.baseUrl}/members/hierarchy");
    final res = await ApiClient.get(url);

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception("Failed to load hierarchy: ${res.body}");
    }
  }

  static Future<bool> softDeleteMember(String id) async {
    final url = Uri.parse("${AuthService.baseUrl}/members/$id/soft-delete");

    final response = await ApiClient.patch(url);

    if (response.statusCode == 200) {
      return true;
    } else {
      return false;
    }
  }

  static Future<bool> updateMember(String id, Map<String, dynamic> data) async {
    final url = Uri.parse("${AuthService.baseUrl}/members/$id");
    final response = await ApiClient.patch(url, body: jsonEncode(data));
    return response.statusCode == 200;
  }

  static Future<bool> createMember(Map<String, dynamic> data) async {
    try {
      final response = await ApiClient.post(
        Uri.parse("$baseUrl/members"),
        body: jsonEncode(data),
      );

      if (response.statusCode == 201) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }
}
