import 'package:hive_ce_flutter/hive_flutter.dart';

class ModelRepository {
  static const _settingsBoxName = 'app_settings';
  static const _activeModelKey = 'active_model_id';
  static const _backendKey = 'preferred_backend';
  static const _maxTokensKey = 'max_tokens';
  static const _themeKey = 'theme_mode';
  static const _gpuKnownBadKey = 'gpu_known_bad';
  static const _gpuAttemptPendingKey = 'gpu_attempt_pending';

  Box get _box => Hive.box(_settingsBoxName);

  static Future<void> openBox() async {
    if (!Hive.isBoxOpen(_settingsBoxName)) {
      await Hive.openBox(_settingsBoxName);
    }
  }

  String? get activeModelId => _box.get(_activeModelKey) as String?;

  Future<void> setActiveModelId(String id) async {
    await _box.put(_activeModelKey, id);
  }

  // 0 = cpu, 1 = gpu (default)
  int get preferredBackendIndex => _box.get(_backendKey, defaultValue: 1) as int;
  Future<void> setPreferredBackendIndex(int i) => _box.put(_backendKey, i);

  int get maxTokens => _box.get(_maxTokensKey, defaultValue: 2048) as int;
  Future<void> setMaxTokens(int v) => _box.put(_maxTokensKey, v);

  // 0 = system, 1 = light, 2 = dark
  int get themeModeIndex => _box.get(_themeKey, defaultValue: 0) as int;
  Future<void> setThemeModeIndex(int i) => _box.put(_themeKey, i);

  // ── GPU crash recovery ──────────────────────────────────────────────────
  // GPU/OpenCL init can crash the whole process natively (SIGSEGV) on devices
  // without a working GPU delegate — a crash Dart can't catch. We persist a
  // flag right before each GPU attempt and clear it on success; if the app
  // restarts and the flag is still set, the previous attempt crashed, so we
  // permanently mark the GPU as unusable and fall back to CPU.

  /// True once a GPU load has crashed on this device — force CPU from then on.
  bool get gpuKnownBad => _box.get(_gpuKnownBadKey, defaultValue: false) as bool;
  Future<void> setGpuKnownBad(bool v) => _box.put(_gpuKnownBadKey, v);

  /// Set immediately before a GPU init, cleared right after it succeeds.
  bool get gpuAttemptPending =>
      _box.get(_gpuAttemptPendingKey, defaultValue: false) as bool;
  Future<void> setGpuAttemptPending(bool v) =>
      _box.put(_gpuAttemptPendingKey, v);
}
