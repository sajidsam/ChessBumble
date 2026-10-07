import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Use 10.0.2.2 for Android emulator to connect to localhost, or localhost for web/iOS
  static const String baseUrl = 'http://127.0.0.1:5000/api';
  
  static Future<Map<String, dynamic>> login(String msic) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'msic': msic}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to login: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<List<dynamic>> fetchInfoFeed() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/info'));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch info: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}
