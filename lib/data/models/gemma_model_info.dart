import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:flutter_gemma/flutter_gemma.dart';

class GemmaModelInfo {
  final String id;
  final String displayName;
  final String description;
  final int sizeMb;
  final String? mobileUrl; // .task for Android/iOS/Web
  final String? desktopUrl; // .litertlm for macOS/Windows/Linux
  final bool supportsImage;
  final bool supportsThinking;
  final bool requiresAuth;
  final ModelType modelType;

  const GemmaModelInfo({
    required this.id,
    required this.displayName,
    required this.description,
    required this.sizeMb,
    this.mobileUrl,
    this.desktopUrl,
    this.supportsImage = false,
    this.supportsThinking = false,
    this.requiresAuth = true,
    this.modelType = ModelType.gemmaIt,
  });

  bool get isDesktopPlatform {
    if (kIsWeb) return false;
    try {
      return Platform.isMacOS || Platform.isWindows || Platform.isLinux;
    } catch (_) {
      return false;
    }
  }

  String? get downloadUrl => isDesktopPlatform ? desktopUrl : mobileUrl;

  ModelFileType get fileType {
    final url = downloadUrl ?? '';
    if (url.endsWith('.litertlm')) return ModelFileType.litertlm;
    return ModelFileType.task;
  }

  bool get isAvailableOnCurrentPlatform => downloadUrl != null;

  String get sizeDisplay {
    if (sizeMb >= 1000) {
      return '${(sizeMb / 1000).toStringAsFixed(1)} GB';
    }
    return '$sizeMb MB';
  }
}
