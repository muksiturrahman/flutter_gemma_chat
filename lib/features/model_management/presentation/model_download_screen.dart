import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    const token = String.fromEnvironment('HUGGINGFACE_TOKEN');
    ref.read(modelInstallProvider.notifier).install(
          info: widget.model,
          authToken: token.isNotEmpty ? token : null,
        );
  }

  @override
  Widget build(BuildContext context) {
    final installState = ref.watch(modelInstallProvider);
    final colorScheme = Theme.of(context).colorScheme;

    // Auto-pop when done
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
        appBar: AppBar(
          title: const Text('Downloading'),
          automaticallyImplyLeading: !installState.isInstalling,
        ),
        body: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.cloud_download_outlined,
                size: 72,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                widget.model.displayName,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                widget.model.sizeDisplay,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: colorScheme.outline),
              ),
              const SizedBox(height: 40),
              if (installState.error != null) ...[
                Icon(Icons.error_outline,
                    size: 48, color: colorScheme.error),
                const SizedBox(height: 12),
                Text(
                  installState.error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colorScheme.error),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _startDownload,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ] else ...[
                LinearProgressIndicator(
                  value: installState.progress / 100,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 12),
                Text(
                  '${installState.progress}%',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  installState.isInstalling
                      ? 'Downloading — keep the app open'
                      : 'Finalizing…',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
