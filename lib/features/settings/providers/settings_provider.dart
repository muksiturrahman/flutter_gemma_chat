import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/model_repository.dart';
import '../../model_management/providers/model_install_provider.dart';

/// Reactive theme mode backed by [ModelRepository].
///
/// [App] watches this provider so theme changes apply instantly on save,
/// rather than only after a relaunch. (Watching [modelRepositoryProvider]
/// directly never rebuilt anything: the repository instance keeps the same
/// identity, so mutating a Hive value behind it is invisible to Riverpod.)
class ThemeModeNotifier extends Notifier<ThemeMode> {
  late final ModelRepository _repo;

  @override
  ThemeMode build() {
    _repo = ref.read(modelRepositoryProvider);
    return _fromIndex(_repo.themeModeIndex);
  }

  /// Persists the new theme (0 = system, 1 = light, 2 = dark) and updates the
  /// in-memory state, which rebuilds every widget watching this provider.
  Future<void> setIndex(int index) async {
    await _repo.setThemeModeIndex(index);
    state = _fromIndex(index);
  }

  static ThemeMode _fromIndex(int index) => switch (index) {
        1 => ThemeMode.light,
        2 => ThemeMode.dark,
        _ => ThemeMode.system,
      };
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);
