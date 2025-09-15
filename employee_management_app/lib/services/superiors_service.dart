import 'dart:convert';
import 'dart:io';
import 'package:employee_management_app/services/api_client.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'auth_service.dart';

class SuperiorsService {
  static String get baseUrl {
    String url = dotenv.env['API_URL'] ?? "";
    if (Platform.isAndroid) {
      url = url.replaceFirst("localhost", "10.0.2.2");
    }
    return url;
  }

  static Future<List<Map<String, dynamic>>> fetchSuperiors() async {
    try {
      final token = await AuthService.getToken();
      final userId = await AuthService.getUserId();

      if (token == null || userId == null) {
        throw Exception("User not logged in");
      }

      final uri = Uri.parse("${AuthService.baseUrl}/superiors");
      final res = await ApiClient.get(uri);

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);

        if (decoded is Map && decoded["data"] is List) {
          return List<Map<String, dynamic>>.from(decoded["data"]);
        }

        if (decoded is List) {
          return List<Map<String, dynamic>>.from(decoded);
        }

        throw Exception("Unexpected response format: $decoded");
      } else {
        throw Exception("Failed to load superiors: ${res.body}");
      }
    } catch (e) {
      rethrow;
    }
  }
}
