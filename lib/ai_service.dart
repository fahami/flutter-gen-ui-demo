import 'package:genkit/genkit.dart';
import 'package:genkit_openai/genkit_openai.dart';

import 'app_config.dart';

abstract interface class AiService {
  Future<String> generate({required String prompt, required String apiKey});
}

final class GenkitAiService implements AiService {
  GenkitAiService({required this.config});

  final AppConfig config;

  @override
  Future<String> generate({
    required String prompt,
    required String apiKey,
  }) async {
    final trimmedPrompt = prompt.trim();
    final trimmedApiKey = apiKey.trim();

    if (trimmedPrompt.isEmpty) {
      throw const AiServiceException('Enter a prompt before generating text.');
    }

    if (trimmedApiKey.isEmpty) {
      throw const AiServiceException(
        'Enter an OpenAI-compatible API key before generating text.',
      );
    }

    try {
      final ai = Genkit(
        plugins: [openAI(apiKey: trimmedApiKey, baseUrl: config.baseUrl)],
      );

      final response = await ai.generate(
        model: openAI.model(config.model),
        prompt: trimmedPrompt,
      );

      final text = response.text.trim();
      if (text.isEmpty) {
        throw const AiServiceException(
          'The model returned an empty response. Try a more specific prompt.',
        );
      }

      return text;
    } on AiServiceException {
      rethrow;
    } catch (error) {
      throw AiServiceException(_messageForError(error));
    }
  }

  String _messageForError(Object error) {
    final rawMessage = error.toString().replaceFirst('Exception: ', '').trim();
    final message = rawMessage.isEmpty ? 'Unknown error.' : rawMessage;
    final lower = message.toLowerCase();

    if (lower.contains('incorrect api key') ||
        lower.contains('invalid api key') ||
        lower.contains('unauthorized') ||
        lower.contains('401')) {
      return 'Authentication failed. Check the API key you entered and try again.';
    }

    if (lower.contains('socketexception') ||
        lower.contains('failed host lookup') ||
        lower.contains('connection refused') ||
        lower.contains('timed out')) {
      return 'Network error while reaching the model endpoint. Check your connection and OPENAI_BASE_URL.';
    }

    if ((lower.contains('model') && lower.contains('not found')) ||
        lower.contains('404')) {
      return 'The configured model or endpoint was not found. Check OPENAI_MODEL and OPENAI_BASE_URL.';
    }

    return 'Request failed. $message';
  }
}

final class AiServiceException implements Exception {
  const AiServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}
