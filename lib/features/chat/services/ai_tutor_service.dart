import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/ai_message_model.dart';

class AiTutorService {
  // ============================================
  // LOCAL BACKEND URL
  // ============================================

  // Android Emulator
  static const String baseUrl = 'http://10.0.2.2:3000';

  Future<String> askAi(List<AiMessageModel> messages) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/chat'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'messages': messages
                  .map((message) => message.toApiMap())
                  .toList(),
            }),
          )
          .timeout(const Duration(seconds: 90));

      final data = jsonDecode(response.body);

      if (response.statusCode != 200) {
        throw Exception(data['message'] ?? 'AI request failed.');
      }

      final answer = data['answer']?.toString() ?? '';

      if (answer.trim().isEmpty) {
        throw Exception('AI returned an empty answer.');
      }

      return answer.trim();
    } catch (e) {
      throw Exception('Failed to get AI answer: $e');
    }
  }
}
