/// Static, compile-time information about the application.
abstract final class AppInfo {
  /// Human-readable product name.
  static const String name = 'Manthan';

  /// One-line product tagline used on the home screen and about page.
  static const String tagline = 'Private, on-device AI. No cloud. No leaks.';

  /// Short description used in the about screen.
  static const String description =
      'Manthan runs large language models entirely on your device. Chat, '
      'reason over images, talk to your own documents, and use your voice '
      'without a single byte leaving the hardware in your hand.';

  /// Public source repository.
  static const String repositoryUrl = 'https://github.com/Ayushd70/manthan';

  /// Author portfolio.
  static const String authorUrl = 'https://ayushd70.dev';

  /// Current semantic version (kept in sync with pubspec).
  static const String version = '0.1.0';
}
