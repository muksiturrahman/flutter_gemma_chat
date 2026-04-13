import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import '../../../data/models/gemma_model_info.dart';
import '../../../data/repositories/model_repository.dart';
import '../../../services/gemma_service.dart';

// ── Repositories ──────────────────────────────────────────────────────────────

final modelRepositoryProvider = Provider<ModelRepository>((ref) {
  return ModelRepository();
});

// ── Active model ID (persisted) ───────────────────────────────────────────────

final activeModelIdProvider =
    StateNotifierProvider<ActiveModelIdNotifier, String?>((ref) {
  final repo = ref.watch(modelRepositoryProvider);
  return ActiveModelIdNotifier(repo);
});

class ActiveModelIdNotifier extends StateNotifier<String?> {
  final ModelRepository _repo;

  ActiveModelIdNotifier(this._repo) : super(_repo.activeModelId);

  Future<void> set(String id) async {
    await _repo.setActiveModelId(id);
    state = id;
  }
}

// ── Model loading state ───────────────────────────────────────────────────────

enum ModelLoadState { idle, loading, ready, error }

class ModelLoadNotifier extends StateNotifier<ModelLoadState> {
  final ModelRepository _repo;

  ModelLoadNotifier(this._repo) : super(ModelLoadState.idle);

  Future<void> loadModel(GemmaModelInfo info) async {
    state = ModelLoadState.loading;
    try {
      final backendIdx = _repo.preferredBackendIndex;
      final backend =
          backendIdx == 0 ? PreferredBackend.cpu : PreferredBackend.gpu;
      await GemmaService.instance.loadModel(
        supportImage: info.supportsImage,
        backend: backend,
        maxTokens: _repo.maxTokens,
      );
      state = ModelLoadState.ready;
    } catch (_) {
      state = ModelLoadState.error;
      rethrow;
    }
  }

  void reset() => state = ModelLoadState.idle;
}

final modelLoadProvider =
    StateNotifierProvider<ModelLoadNotifier, ModelLoadState>((ref) {
  return ModelLoadNotifier(ref.watch(modelRepositoryProvider));
});

// ── Installation stream ───────────────────────────────────────────────────────

class InstallState {
  final bool isInstalling;
  final int progress;
  final String? error;

  const InstallState({
    this.isInstalling = false,
    this.progress = 0,
    this.error,
  });

  InstallState copyWith({bool? isInstalling, int? progress, String? error}) =>
      InstallState(
        isInstalling: isInstalling ?? this.isInstalling,
        progress: progress ?? this.progress,
        error: error,
      );
}

class ModelInstallNotifier extends StateNotifier<InstallState> {
  ModelInstallNotifier() : super(const InstallState());

  Future<void> install({
    required GemmaModelInfo info,
    required String? authToken,
  }) async {
    final url = info.downloadUrl;
    if (url == null) {
      state = state.copyWith(
          error: 'No download URL available for this platform.');
      return;
    }

    state = const InstallState(isInstalling: true, progress: 0);

    final stream = GemmaService.instance.installModelFromNetwork(
      url: url,
      modelId: info.id,
      modelType: info.modelType,
      fileType: info.fileType,
      authToken: authToken,
    );

    await for (final p in stream) {
      state = state.copyWith(progress: p);
    }

    state = const InstallState(isInstalling: false, progress: 100);
  }

  void reset() => state = const InstallState();
}

final modelInstallProvider =
    StateNotifierProvider<ModelInstallNotifier, InstallState>((ref) {
  return ModelInstallNotifier();
});
