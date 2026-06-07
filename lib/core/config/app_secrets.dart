import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centralized access to runtime secrets.
///
/// The HuggingFace token is required to download the gated Gemma models.
/// It can be provided either at compile time via
/// `--dart-define=HUGGINGFACE_TOKEN=hf_...` or at runtime through `lib/.env`
/// (key `HUGGINGFACE_TOKEN`). The dart-define value wins when both are set.
class AppSecrets {
  AppSecrets._();

  static const _envKey = 'HUGGINGFACE_TOKEN';
  static const _compileTimeToken = String.fromEnvironment(_envKey);

  /// Loads `lib/.env`. Safe to call once at startup; failures are ignored so
  /// the app still runs (downloads will just fail with an auth error instead).
  static Future<void> load() async {
    try {
      await dotenv.load(fileName: 'lib/.env');
    } catch (_) {
      // No .env bundled — fall back to dart-define (or no token at all).
    }
  }

  /// The HuggingFace token, or null when none was configured.
  static String? get huggingFaceToken {
    if (_compileTimeToken.isNotEmpty) return _compileTimeToken;
    final fromEnv = dotenv.isInitialized ? dotenv.maybeGet(_envKey) : null;
    return (fromEnv != null && fromEnv.isNotEmpty) ? fromEnv : null;
  }
}
