import 'package:flutter/material.dart';
import 'package:flutter_gemma/flutter_gemma.dart' show FlutterGemma;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/gemma_model_info.dart';
import '../../../data/sources/model_registry.dart';
import '../providers/model_install_provider.dart';
import 'model_download_screen.dart';

class ModelPickerScreen extends ConsumerWidget {
  const ModelPickerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeId = ref.watch(activeModelIdProvider);
    final loadState = ref.watch(modelLoadProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Model'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: kModelRegistry.length,
        separatorBuilder: (_, i) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final model = kModelRegistry[i];
          return _ModelCard(
            model: model,
            isActive: model.id == activeId,
            isLoading: loadState == ModelLoadState.loading,
            onSelect: () => _onSelect(context, ref, model),
          );
        },
      ),
    );
  }

  Future<void> _onSelect(
      BuildContext context, WidgetRef ref, GemmaModelInfo model) async {
    if (!model.isAvailableOnCurrentPlatform) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('This model is not available on your platform.')),
      );
      return;
    }

    final filename = model.downloadUrl?.split('/').last ?? '';
    final isInstalled =
        filename.isNotEmpty && await FlutterGemma.isModelInstalled(filename);

    if (!isInstalled && context.mounted) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => _DownloadConfirmDialog(model: model),
      );
      if (confirmed != true || !context.mounted) return;

      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ModelDownloadScreen(model: model)),
      );
    }

    if (!context.mounted) return;
    await ref.read(activeModelIdProvider.notifier).set(model.id);
    try {
      await ref.read(modelLoadProvider.notifier).loadModel(model);
      if (context.mounted) context.go('/chat');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load model: $e')),
        );
      }
    }
  }
}

class _ModelCard extends StatelessWidget {
  final GemmaModelInfo model;
  final bool isActive;
  final bool isLoading;
  final VoidCallback onSelect;

  const _ModelCard({
    required this.model,
    required this.isActive,
    required this.isLoading,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final unavailable = !model.isAvailableOnCurrentPlatform;

    return Card(
      elevation: isActive ? 3 : 1,
      color: isActive ? colorScheme.primaryContainer : null,
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: isActive
              ? colorScheme.primary
              : colorScheme.surfaceContainerHighest,
          child: Icon(
            model.supportsImage ? Icons.image_outlined : Icons.chat_outlined,
            color: isActive ? colorScheme.onPrimary : colorScheme.onSurface,
          ),
        ),
        title: Text(
          model.displayName,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(model.description,
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              children: [
                _Chip(model.sizeDisplay, Icons.storage_outlined),
                if (model.supportsImage)
                  _Chip('Multimodal', Icons.image_outlined),
                if (model.supportsThinking)
                  _Chip('Thinking', Icons.psychology_outlined),
                if (unavailable)
                  _Chip('Not available', Icons.block_outlined, isError: true),
              ],
            ),
          ],
        ),
        trailing: isActive && isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : isActive
                ? Icon(Icons.check_circle, color: colorScheme.primary)
                : Icon(
                    unavailable ? Icons.block : Icons.download_outlined,
                    color: unavailable
                        ? colorScheme.error
                        : colorScheme.onSurfaceVariant,
                  ),
        onTap: unavailable ? null : onSelect,
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isError;

  const _Chip(this.label, this.icon, {this.isError = false});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon,
            size: 12,
            color: isError ? colorScheme.error : colorScheme.outline),
        const SizedBox(width: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: isError ? colorScheme.error : colorScheme.outline,
              ),
        ),
      ],
    );
  }
}

class _DownloadConfirmDialog extends StatelessWidget {
  final GemmaModelInfo model;

  const _DownloadConfirmDialog({required this.model});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Download Model'),
      content: Text(
        'Download ${model.displayName} (${model.sizeDisplay})?\n\n'
        'This will use device storage. A HuggingFace account and accepted '
        'license are required.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Download'),
        ),
      ],
    );
  }
}
