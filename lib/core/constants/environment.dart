class Environment {
  Environment._();

  static const String liveKitUrl = String.fromEnvironment(
    'LIVEKIT_URL',
      defaultValue: 'ws://192.168.1.186:7880',
  );

  static const String apiKey = String.fromEnvironment(
    'LIVEKIT_API_KEY',
    defaultValue: 'devkey',
  );

  static const String apiSecret = String.fromEnvironment(
    'LIVEKIT_API_SECRET',
    defaultValue: 'secret',
  );

  static bool get isProduction =>
      const bool.fromEnvironment('PRODUCTION', defaultValue: false);
}
