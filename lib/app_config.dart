class AppConfig {
  const AppConfig({this.model = defaultModel, this.baseUrl = defaultBaseUrl});

  static const String defaultModel = 'gpt-4o-mini';
  static const String defaultBaseUrl = 'https://api.openai.com/v1';

  final String model;
  final String baseUrl;

  factory AppConfig.fromEnvironment() {
    return const AppConfig(
      model: String.fromEnvironment('OPENAI_MODEL', defaultValue: defaultModel),
      baseUrl: String.fromEnvironment(
        'OPENAI_BASE_URL',
        defaultValue: defaultBaseUrl,
      ),
    );
  }
}

class EndpointPreset {
  const EndpointPreset({
    required this.id,
    required this.label,
    required this.baseUrl,
    required this.helperText,
    this.isCustom = false,
  });

  final String id;
  final String label;
  final String baseUrl;
  final String helperText;
  final bool isCustom;

  static const EndpointPreset openAI = EndpointPreset(
    id: 'openai',
    label: 'OpenAI',
    baseUrl: 'https://api.openai.com/v1',
    helperText: 'Official OpenAI API endpoint.',
  );

  static const EndpointPreset openRouter = EndpointPreset(
    id: 'openrouter',
    label: 'OpenRouter',
    baseUrl: 'https://openrouter.ai/api/v1',
    helperText:
        'OpenRouter gateway for OpenAI-compatible requests and provider routing.',
  );

  static const EndpointPreset groq = EndpointPreset(
    id: 'groq',
    label: 'Groq',
    baseUrl: 'https://api.groq.com/openai/v1',
    helperText: 'Groq OpenAI-compatible endpoint for Groq-hosted models.',
  );

  static const EndpointPreset custom = EndpointPreset(
    id: 'custom',
    label: 'Custom URL',
    baseUrl: '',
    helperText: 'Use any OpenAI-compatible base URL.',
    isCustom: true,
  );

  static const List<EndpointPreset> values = [openAI, openRouter, groq, custom];

  static EndpointPreset fromBaseUrl(String baseUrl) {
    final normalized = _normalize(baseUrl);
    for (final preset in values.where((preset) => !preset.isCustom)) {
      if (_normalize(preset.baseUrl) == normalized) {
        return preset;
      }
    }
    return custom;
  }

  static String _normalize(String value) {
    return value.trim().replaceFirst(RegExp(r'/$'), '').toLowerCase();
  }
}
