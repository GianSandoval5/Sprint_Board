class AppConfig {
  const AppConfig._();

  static const String appName = 'SprintBoard';
  static const String baseUrl = 'https://app.backboard.io/api';
  static const String defaultProvider = 'openai';
  static const String defaultModel = 'gpt-4o';
  static const String preloadedApiKey = String.fromEnvironment(
    'BACKBOARD_API_KEY',
    defaultValue: '',
  );
}
