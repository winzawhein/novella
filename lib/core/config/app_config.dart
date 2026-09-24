abstract final class AppConfig {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );
  static void validate() {
    if (supabaseUrl.isEmpty || supabasePublishableKey.isEmpty)
      throw StateError('Missing SUPABASE_URL or SUPABASE_PUBLISHABLE_KEY.');
  }
}
