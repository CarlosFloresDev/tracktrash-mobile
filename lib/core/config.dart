import 'package:flutter/foundation.dart';

abstract final class AppConfig {
  static const apiUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:5080',
  );
  static const demoMode = bool.fromEnvironment(
    'DEMO_MODE',
    defaultValue: !kReleaseMode,
  );
}
