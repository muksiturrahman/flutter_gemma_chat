import 'dart:async';
import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart';

/// Singleton service wrapping flutter_gemma.
/// Owns the model lifecycle and a per-thread chat session cache (LRU max 3).
class GemmaService {
  GemmaService._();
  static final GemmaService instance = GemmaService._();

  InferenceModel? _model;
  bool _initialized = false;

  // LRU cache: threadId → InferenceChat (max 3 live sessions)
  final _chatCache = <String, InferenceChat>{};
  final _cacheOrder = <String>[];
  static const _maxCachedSessions = 3;

  bool _supportsImage = false;

  // ── Initialization ────────────────────────────────────────────────────────

  Future<void> initialize({String? huggingFaceToken}) async {
    if (_initialized) return;
    await FlutterGemma.initialize(
      huggingFaceToken: huggingFaceToken,
      maxDownloadRetries: 10,
      webStorageMode: WebStorageMode.cacheApi,
    );
    _initialized = true;
  }

  bool get hasActiveModel => FlutterGemma.hasActiveModel();

  // ── Download maintenance ──────────────────────────────────────────────────

  /// flutter_gemma's smart downloader derives a deterministic task id from the
  /// URL and attaches to any pre-existing task with that id. A download that
  /// was interrupted (app killed, earlier auth failure) can leave a ghost task
  /// in background_downloader's database — the next attempt then attaches to it
  /// and waits forever for updates that never arrive, so the progress bar is
  /// stuck at 0%. Cancelling the group's tasks clears those ghosts so a fresh
  /// download can start.
  static const _downloadGroup = 'smart_downloads';

  Future<void> clearStaleDownloads() async {
    try {
      await FileDownloader().reset(group: _downloadGroup);
      await FileDownloader().cancelAll(group: _downloadGroup);
    } catch (e) {
      debugPrint('GemmaService: clearStaleDownloads failed ($e)');
    }
  }

  // ── Model installation ────────────────────────────────────────────────────

  /// Returns a stream of download progress (0–100).
  Stream<int> installModelFromNetwork({
    required String url,
    required String modelId,
    required ModelType modelType,
    required ModelFileType fileType,
    String? authToken,
  }) {
    final controller = StreamController<int>.broadcast();

    FlutterGemma.installModel(modelType: modelType, fileType: fileType)
        .fromNetwork(url, token: authToken)
        .withProgress((p) => controller.add(p))
        .install()
        .then((_) {
      controller.add(100);
      controller.close();
    }).catchError((e) {
      controller.addError(e);
      controller.close();
    });

    return controller.stream;
  }

  /// Registers an already-downloaded model as the active inference model
  /// without re-downloading it.
  ///
  /// flutter_gemma's `getActiveModel()` reads in-memory state that is only
  /// populated by `installModel().install()` — and that state is lost on every
  /// app restart. When the model file already exists on disk, `install()`
  /// detects it, skips the network download, and just re-sets the active spec,
  /// so this is cheap to call every time before loading.
  Future<void> ensureModelRegistered({
    required String url,
    required ModelType modelType,
    required ModelFileType fileType,
    String? authToken,
  }) async {
    await FlutterGemma.installModel(modelType: modelType, fileType: fileType)
        .fromNetwork(url, token: authToken)
        .install();
  }

  // ── Model loading ─────────────────────────────────────────────────────────

  Future<void> loadModel({
    bool supportImage = false,
    bool supportAudio = false,
    PreferredBackend? backend,
    int maxTokens = 2048,
  }) async {
    _supportsImage = supportImage;
    _closeAllSessions();

    try {
      _model = await FlutterGemma.getActiveModel(
        maxTokens: maxTokens,
        preferredBackend: backend ?? PreferredBackend.gpu,
        supportImage: supportImage,
        supportAudio: supportAudio,
      );
    } catch (e) {
      // GPU not available — fall back to CPU
      debugPrint('GemmaService: GPU init failed ($e), retrying with CPU');
      _model = await FlutterGemma.getActiveModel(
        maxTokens: maxTokens,
        preferredBackend: PreferredBackend.cpu,
        supportImage: supportImage,
      );
    }
  }

  Future<void> closeModel() async {
    _closeAllSessions();
    _model = null;
  }

  // ── Chat sessions ─────────────────────────────────────────────────────────

  Future<InferenceChat> chatForThread(
    String threadId, {
    bool isThinking = false,
    String? systemInstruction,
  }) async {
    if (_model == null) {
      throw StateError('Model not loaded. Call loadModel() first.');
    }

    if (_chatCache.containsKey(threadId)) {
      _touch(threadId);
      return _chatCache[threadId]!;
    }

    final chat = await _model!.createChat(
      temperature: 0.8,
      topK: 40,
      tokenBuffer: 256,
      supportImage: _supportsImage,
      isThinking: isThinking,
      modelType: ModelType.gemmaIt,
      systemInstruction: systemInstruction,
    );
    await chat.initSession();
    _addToCache(threadId, chat);
    return chat;
  }

  Future<void> evictSession(String threadId) async {
    final chat = _chatCache.remove(threadId);
    _cacheOrder.remove(threadId);
    await chat?.close();
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  void _addToCache(String id, InferenceChat chat) {
    if (_cacheOrder.length >= _maxCachedSessions) {
      final evict = _cacheOrder.removeAt(0);
      _chatCache.remove(evict)?.close();
    }
    _chatCache[id] = chat;
    _cacheOrder.add(id);
  }

  void _touch(String id) {
    _cacheOrder.remove(id);
    _cacheOrder.add(id);
  }

  void _closeAllSessions() {
    for (final chat in _chatCache.values) {
      chat.close();
    }
    _chatCache.clear();
    _cacheOrder.clear();
  }
}
