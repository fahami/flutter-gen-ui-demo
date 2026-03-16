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
