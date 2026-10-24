import 'package:flutter/foundation.dart';

abstract final class AppConfig {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
  static const authConfigured = supabaseUrl != '' && supabaseKey != '';
  static const apiUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:5080',
  );
  static const demoMode = bool.fromEnvironment(
    'DEMO_MODE',
    defaultValue: !kReleaseMode,
  );
}
