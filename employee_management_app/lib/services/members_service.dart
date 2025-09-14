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
}
