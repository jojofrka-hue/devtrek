import 'dart:convert';

import 'package:http/http.dart' as http;

import 'settings_service.dart';

class AiExplanation {
  const AiExplanation({required this.ok, required this.text});

  final bool ok;
  final String text;
}

/// Talks to the small proxy server in `server/` which holds the Claude API key.
/// The key is never shipped inside the Flutter app.
class AiTutorService {
  AiTutorService({
    required this.settings,
    http.Client? client,
    this.timeout = const Duration(seconds: 20),
  }) : _client = client ?? http.Client();

  final SettingsService settings;
  final http.Client _client;
  final Duration timeout;

  Future<AiExplanation> explainMistake({
    required String language,
    required String question,
    required String userAnswer,
    required String correctAnswer,
    String? code,
  }) async {
    final uri = Uri.parse('${settings.aiServerUrl}/explain');
    try {
      final response = await _client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'language': language,
              'question': question,
              'userAnswer': userAnswer,
              'correctAnswer': correctAnswer,
              'code': code,
            }),
          )
          .timeout(timeout);

      if (response.statusCode != 200) {
        return AiExplanation(
          ok: false,
          text: 'Server returned ${response.statusCode}',
        );
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final text = (decoded['explanation'] as String?)?.trim() ?? '';
      if (text.isEmpty) {
        return const AiExplanation(ok: false, text: 'Empty response');
      }
      return AiExplanation(ok: true, text: text);
    } catch (error) {
      return AiExplanation(ok: false, text: '$error');
    }
  }
}
