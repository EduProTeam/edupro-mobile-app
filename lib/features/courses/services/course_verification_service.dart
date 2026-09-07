import 'dart:convert';

import 'package:http/http.dart' as http;

class VerificationQuestion {
  const VerificationQuestion({required this.question, required this.options});

  final String question;
  final List<String> options;

  factory VerificationQuestion.fromMap(Map<String, dynamic> data) {
    final options = (data['options'] as List? ?? []).whereType<String>().toList();
    if ((data['question'] as String? ?? '').trim().isEmpty || options.length != 4) {
      throw const CourseVerificationFailure('The quiz returned invalid questions. Please try again.');
    }
    return VerificationQuestion(question: data['question'] as String, options: options);
  }
}

class GeneratedVerificationQuiz {
  const GeneratedVerificationQuiz({required this.id, required this.questions});

  final String id;
  final List<VerificationQuestion> questions;
}

class VerificationResult {
  const VerificationResult({required this.passed, required this.score});
  final bool passed;
  final int score;
}

/// Demo-only direct Gemini client. It intentionally keeps the answer key only
/// in this running app instance; this is not suitable for production security.
class CourseVerificationService {
  CourseVerificationService({http.Client? client}) : _client = client ?? http.Client();

  static const _apiKey = String.fromEnvironment('GEMINI_API_KEY');
  final http.Client _client;
  final Map<String, List<int>> _answerKeys = {};

  Future<GeneratedVerificationQuiz> generate({
    required String title,
    required String category,
    required String courseId,
  }) async {
    if (_apiKey.isEmpty) {
      throw const CourseVerificationFailure('Gemini is not configured. Start the app with GEMINI_API_KEY.');
    }
    try {
      final response = await _client.post(
        Uri.https(
          'generativelanguage.googleapis.com',
          '/v1beta/models/gemini-2.0-flash:generateContent',
          {'key': _apiKey},
        ),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'text': 'Generate exactly 10 fair multiple-choice questions about a proposed online course. Course title: $title. Category: $category. Each question needs exactly four concise options and one correct answer.',
                },
              ],
            },
          ],
          'generationConfig': {
            'response_mime_type': 'application/json',
            'response_schema': {
              'type': 'OBJECT',
              'properties': {
                'questions': {
                  'type': 'ARRAY',
                  'items': {
                    'type': 'OBJECT',
                    'properties': {
                      'question': {'type': 'STRING'},
                      'options': {
                        'type': 'ARRAY',
                        'items': {'type': 'STRING'},
                      },
                      'correctIndex': {'type': 'INTEGER'},
                    },
                    'required': ['question', 'options', 'correctIndex'],
                  },
                },
              },
              'required': ['questions'],
            },
          },
        }),
      );
      if (response.statusCode == 429) {
        throw const CourseVerificationFailure('Gemini is busy or has reached its free limit. Please try again shortly.');
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw const CourseVerificationFailure('Gemini could not create a quiz. Please try again.');
      }
      final payload = Map<String, dynamic>.from(jsonDecode(response.body) as Map);
      final candidates = payload['candidates'] as List? ?? [];
      final first = candidates.isEmpty ? null : candidates.first as Map?;
      final parts = first?['content'] is Map ? (first!['content'] as Map)['parts'] as List? : null;
      final text = parts?.isNotEmpty == true ? (parts!.first as Map)['text'] as String? : null;
      if (text == null) throw const FormatException();
      final generated = Map<String, dynamic>.from(
        jsonDecode(text.replaceAll(RegExp(r'^```json\s*|\s*```$'), '')) as Map,
      );
      final rawQuestions = (generated['questions'] as List? ?? [])
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
      final answers = rawQuestions
          .map((item) => (item['correctIndex'] as num?)?.toInt())
          .toList();
      if (rawQuestions.length != 10 || answers.any((answer) => answer == null || answer < 0 || answer > 3)) {
        throw const FormatException();
      }
      final quizId = '${DateTime.now().microsecondsSinceEpoch}-$courseId';
      _answerKeys[quizId] = answers.cast<int>();
      return GeneratedVerificationQuiz(
        id: quizId,
        questions: rawQuestions.map(VerificationQuestion.fromMap).toList(),
      );
    } on CourseVerificationFailure {
      rethrow;
    } catch (_) {
      throw const CourseVerificationFailure('Could not create the verification quiz. Please try again.');
    }
  }

  Future<VerificationResult> submit({
    required String quizId,
    required List<int> answers,
  }) async {
    final answerKey = _answerKeys.remove(quizId);
    if (answerKey == null || answers.length != 10) {
      throw const CourseVerificationFailure('This quiz expired. Please generate a new quiz.');
    }
    final score = List.generate(10, (index) => answers[index] == answerKey[index] ? 1 : 0)
        .reduce((total, point) => total + point);
    return VerificationResult(passed: score >= 7, score: score);
  }
}

class CourseVerificationFailure implements Exception {
  const CourseVerificationFailure(this.message);
  final String message;
}
