import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_secrets.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../data/models/gemma_model_info.dart';
import '../providers/model_install_provider.dart';

class ModelDownloadScreen extends ConsumerStatefulWidget {
  final GemmaModelInfo model;

  const ModelDownloadScreen({super.key, required this.model});

  @override
  ConsumerState<ModelDownloadScreen> createState() =>
      _ModelDownloadScreenState();
}

class _ModelDownloadScreenState extends ConsumerState<ModelDownloadScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startDownload());
  }

  void _startDownload() {
    ref.read(modelInstallProvider.notifier).install(
          info: widget.model,
          authToken: AppSecrets.huggingFaceToken,
        );
  }

  @override
  Widget build(BuildContext context) {
    final installState = ref.watch(modelInstallProvider);
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!installState.isInstalling &&
        installState.progress == 100 &&
        installState.error == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop();
      });
    }

    return PopScope(
      canPop: !installState.isInstalling,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
              child: AppBar(
                title: const Text('Downloading'),
                automaticallyImplyLeading: !installState.isInstalling,
                backgroundColor: (isDark ? Colors.white : Colors.white)
                    .withValues(alpha: isDark ? 0.06 : 0.35),
                surfaceTintColor: Colors.transparent,
                elevation: 0,
              ),
            ),
          ),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: GlassContainer(
              padding: const EdgeInsets.all(32),
              borderRadius: BorderRadius.circular(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [scheme.primary, scheme.tertiary],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: scheme.primary.withValues(alpha: 0.45),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Icon(
                        installState.error != null
                            ? Icons.error_outline_rounded
                            : Icons.cloud_download_rounded,
                        size: 38,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    widget.model.displayName,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.model.sizeDisplay,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.6),
                        ),
                  ),
                  const SizedBox(height: 32),
                  if (installState.error != null) ...[
                    Text(
                      installState.error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: scheme.error, height: 1.4),
                    ),
                    const SizedBox(height: 22),
                    FilledButton.icon(
                      onPressed: _startDownload,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Retry'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ] else ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: installState.progress / 100,
                        minHeight: 10,
                        backgroundColor:
                            scheme.onSurface.withValues(alpha: 0.12),
                        valueColor:
                            AlwaysStoppedAnimation(scheme.primary),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${installState.progress}%',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                color: scheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        if (installState.speedKBps > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: scheme.primary.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.speed_rounded,
                                    size: 13, color: scheme.primary),
                                const SizedBox(width: 4),
                                Text(
                                  _formatSpeed(installState.speedKBps),
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(
                                        color: scheme.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_formatBytes(installState.downloadedKb)}  /  '
                          '${_formatBytes(installState.totalKb)}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: scheme.onSurface.withValues(alpha: 0.85),
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                        if (installState.etaSeconds != null)
                          Text(
                            '${_formatDuration(installState.etaSeconds!)} left',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurface
                                      .withValues(alpha: 0.6),
                                ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      installState.isInstalling
                          ? 'Downloading — keep the app open'
                          : 'Finalizing…',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.55),
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _formatBytes(int kb) {
  if (kb >= 1024 * 1024) {
    return '${(kb / 1024 / 1024).toStringAsFixed(2)} GB';
  }
  if (kb >= 1024) {
    return '${(kb / 1024).toStringAsFixed(1)} MB';
  }
  return '$kb KB';
}

String _formatSpeed(double kbps) {
  if (kbps >= 1024) {
    return '${(kbps / 1024).toStringAsFixed(1)} MB/s';
  }
  return '${kbps.toStringAsFixed(0)} KB/s';
}

String _formatDuration(int seconds) {
  if (seconds < 60) return '${seconds}s';
  if (seconds < 3600) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return s == 0 ? '${m}m' : '${m}m ${s}s';
  }
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  return m == 0 ? '${h}h' : '${h}h ${m}m';
}
