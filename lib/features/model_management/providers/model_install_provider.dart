import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import '../../../core/config/app_secrets.dart';
import '../../../core/config/device_capabilities.dart';
import '../../../data/models/gemma_model_info.dart';
import '../../../data/repositories/model_repository.dart';
import '../../../services/gemma_service.dart';

// ── Repositories ──────────────────────────────────────────────────────────────

final modelRepositoryProvider = Provider<ModelRepository>((ref) {
  return ModelRepository();
});

// ── Active model ID (persisted) ───────────────────────────────────────────────

class ActiveModelIdNotifier extends Notifier<String?> {
  late final ModelRepository _repo;

  @override
  String? build() {
    _repo = ref.read(modelRepositoryProvider);
    return _repo.activeModelId;
  }

  Future<void> set(String id) async {
    await _repo.setActiveModelId(id);
    state = id;
  }
}

final activeModelIdProvider =
    NotifierProvider<ActiveModelIdNotifier, String?>(
  ActiveModelIdNotifier.new,
);

// ── Model loading state ───────────────────────────────────────────────────────

enum ModelLoadState { idle, loading, ready, error }

class ModelLoadNotifier extends Notifier<ModelLoadState> {
  late final ModelRepository _repo;

  @override
  ModelLoadState build() {
    _repo = ref.read(modelRepositoryProvider);
    return ModelLoadState.idle;
  }

  Future<void> loadModel(GemmaModelInfo info) async {
    state = ModelLoadState.loading;
    try {
      // Re-register the (already downloaded) model as active. The active spec
      // lives in memory and is cleared on every app restart, so getActiveModel
      // would otherwise throw "No active inference model set".
      final url = info.downloadUrl;
      if (url != null) {
        await GemmaService.instance.ensureModelRegistered(
          url: url,
          modelType: info.modelType,
          fileType: info.fileType,
          authToken: AppSecrets.huggingFaceToken,
        );
      }

      // GPU init can crash the process natively (SIGSEGV) on devices without a
      // working OpenCL/GPU delegate — emulators always, and some real devices.
      // A native crash can't be caught, so we guard it three ways:
      //   1. never use GPU on emulators (no OpenCL at all),
      //   2. never use GPU once it has crashed here before (gpuKnownBad),
      //   3. set a persisted "pending" flag before the attempt; if the app
      //      dies during it, main() sees the flag next launch and disables GPU.
      final prefersGpu = _repo.preferredBackendIndex != 0;
      final canUseGpu = await DeviceCapabilities.canUseGpu;
      final useGpu = prefersGpu && canUseGpu && !_repo.gpuKnownBad;

      if (useGpu) {
        await _repo.setGpuAttemptPending(true);
      }
      await GemmaService.instance.loadModel(
        supportImage: info.supportsImage,
        backend: useGpu ? PreferredBackend.gpu : PreferredBackend.cpu,
        maxTokens: _repo.maxTokens,
      );
      if (useGpu) {
        await _repo.setGpuAttemptPending(false);
      }
      state = ModelLoadState.ready;
    } catch (_) {
      state = ModelLoadState.error;
      rethrow;
    }
  }

  void reset() => state = ModelLoadState.idle;
}

final modelLoadProvider =
    NotifierProvider<ModelLoadNotifier, ModelLoadState>(
  ModelLoadNotifier.new,
);

// ── Installation stream ───────────────────────────────────────────────────────

class InstallState {
  final bool isInstalling;
  final int progress; // 0–100
  final int downloadedKb;
  final int totalKb;
  final double speedKBps; // smoothed
  final int? etaSeconds;
  final String? error;

  const InstallState({
    this.isInstalling = false,
    this.progress = 0,
    this.downloadedKb = 0,
    this.totalKb = 0,
    this.speedKBps = 0,
    this.etaSeconds,
    this.error,
  });

  InstallState copyWith({
    bool? isInstalling,
    int? progress,
    int? downloadedKb,
    int? totalKb,
    double? speedKBps,
    int? etaSeconds,
    String? error,
  }) =>
      InstallState(
        isInstalling: isInstalling ?? this.isInstalling,
        progress: progress ?? this.progress,
        downloadedKb: downloadedKb ?? this.downloadedKb,
        totalKb: totalKb ?? this.totalKb,
        speedKBps: speedKBps ?? this.speedKBps,
        etaSeconds: etaSeconds,
        error: error,
      );
}

class ModelInstallNotifier extends Notifier<InstallState> {
  @override
  InstallState build() => const InstallState();

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

    final totalKb = info.sizeMb * 1024;
    state = InstallState(
      isInstalling: true,
      progress: 0,
      totalKb: totalKb,
    );

    // Clear any ghost download task left by a previous interrupted/failed
    // attempt, otherwise the new download attaches to it and hangs at 0%.
    await GemmaService.instance.clearStaleDownloads();

    final stream = GemmaService.instance.installModelFromNetwork(
      url: url,
      modelId: info.id,
      modelType: info.modelType,
      fileType: info.fileType,
      authToken: authToken,
    );

    DateTime lastSampleTime = DateTime.now();
    int lastSampleKb = 0;
    double smoothedKBps = 0;

    try {
      await for (final p in stream) {
        // Negative progress = download lib's failure signal.
        if (p < 0) {
          throw Exception(
              'Download failed — network unstable. Try a smaller model or a real device.');
        }

        final now = DateTime.now();
        final downloadedKb = (p * totalKb / 100).round();

        // Retry happened — progress jumped backwards. Reset the speed tracker
        // so we don't compute a giant negative speed.
        if (downloadedKb < lastSampleKb) {
          lastSampleKb = downloadedKb;
          lastSampleTime = now;
          smoothedKBps = 0;
          state = state.copyWith(
            progress: p,
            downloadedKb: downloadedKb,
            speedKBps: 0,
            etaSeconds: null,
          );
          continue;
        }

        // Always update progress + bytes for a smooth bar.
        state = state.copyWith(
          progress: p,
          downloadedKb: downloadedKb,
        );

        // Sample speed/ETA 4x/sec — fast enough to feel live, slow enough
        // that EMA actually smooths the jitter.
        final dt = now.difference(lastSampleTime).inMilliseconds / 1000.0;
        if (dt >= 0.25) {
          final deltaKb = downloadedKb - lastSampleKb;
          final instantKBps = deltaKb / dt;
          smoothedKBps = smoothedKBps == 0
              ? instantKBps
              : 0.4 * instantKBps + 0.6 * smoothedKBps;

          final remainingKb = totalKb - downloadedKb;
          final etaSeconds = smoothedKBps > 0.5
              ? (remainingKb / smoothedKBps).round()
              : null;

          state = state.copyWith(
            speedKBps: smoothedKBps,
            etaSeconds: etaSeconds,
          );

          lastSampleTime = now;
          lastSampleKb = downloadedKb;
        }
      }
      state = InstallState(
        isInstalling: false,
        progress: 100,
        totalKb: totalKb,
        downloadedKb: totalKb,
      );
    } catch (e) {
      state = state.copyWith(
        isInstalling: false,
        error: e.toString(),
      );
    }
  }

  void reset() => state = const InstallState();
}

final modelInstallProvider =
    NotifierProvider<ModelInstallNotifier, InstallState>(
  ModelInstallNotifier.new,
);
