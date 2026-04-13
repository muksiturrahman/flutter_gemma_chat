import 'package:hive_ce_flutter/hive_flutter.dart';

class ModelRepository {
  static const _settingsBoxName = 'app_settings';
  static const _activeModelKey = 'active_model_id';
  static const _backendKey = 'preferred_backend';
  static const _maxTokensKey = 'max_tokens';
  static const _themeKey = 'theme_mode';

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
}
