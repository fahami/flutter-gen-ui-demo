import 'package:genkit/genkit.dart';
import 'package:genkit_openai/genkit_openai.dart';

abstract interface class AiService {
  Future<String> generate({
    required String prompt,
    required String apiKey,
    required String model,
    required String baseUrl,
  });
}

final class GenkitAiService implements AiService {
  @override
  Future<String> generate({
    required String prompt,
    required String apiKey,
    required String model,
    required String baseUrl,
  }) async {
    final trimmedPrompt = prompt.trim();
    final trimmedApiKey = apiKey.trim();
    final trimmedModel = model.trim();
    final trimmedBaseUrl = baseUrl.trim();

    if (trimmedPrompt.isEmpty) {
      throw const AiServiceException('Enter a prompt before generating text.');
    }

    if (trimmedApiKey.isEmpty) {
      throw const AiServiceException(
        'Enter an OpenAI-compatible API key before generating text.',
      );
    }

    if (trimmedModel.isEmpty) {
      throw const AiServiceException(
        'Enter a model name for the selected endpoint.',
      );
    }

    final endpointUri = Uri.tryParse(trimmedBaseUrl);
    if (endpointUri == null ||
        !endpointUri.hasScheme ||
        (endpointUri.host.isEmpty && endpointUri.authority.isEmpty)) {
      throw const AiServiceException(
        'Enter a valid endpoint URL before generating text.',
      );
    }

    try {
      final ai = Genkit(
        plugins: [openAI(apiKey: trimmedApiKey, baseUrl: trimmedBaseUrl)],
      );

      final response = await ai.generate(
        model: openAI.model(trimmedModel),
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
      return 'Authentication failed. Check the API key and selected endpoint.';
    }

    if (lower.contains('socketexception') ||
        lower.contains('failed host lookup') ||
        lower.contains('connection refused') ||
        lower.contains('timed out')) {
      return 'Network error while reaching the selected endpoint. Check the URL and your connection.';
    }

    if ((lower.contains('model') && lower.contains('not found')) ||
        lower.contains('404')) {
      return 'The selected model or endpoint was not found. Check the model name for the chosen provider.';
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
