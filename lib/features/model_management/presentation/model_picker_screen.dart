import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_gemma/flutter_gemma.dart' show FlutterGemma;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/glass_container.dart';
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
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: _GlassAppBar(
        title: 'Select Model',
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 96, 16, 24),
        itemCount: kModelRegistry.length,
        separatorBuilder: (_, i) => const SizedBox(height: 12),
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

class _GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;

  const _GlassAppBar({required this.title, this.actions});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: AppBar(
          title: Text(title),
          actions: actions,
          backgroundColor: (isDark ? Colors.white : Colors.white)
              .withValues(alpha: isDark ? 0.06 : 0.35),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
      ),
    );
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
    final scheme = Theme.of(context).colorScheme;
    final unavailable = !model.isAvailableOnCurrentPlatform;

    return GlassCard(
      onTap: unavailable ? null : onSelect,
      padding: const EdgeInsets.all(16),
      tint: isActive ? scheme.primary : null,
      opacity: isActive ? 0.18 : 0.14,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: isActive
                        ? [scheme.primary, scheme.tertiary]
                        : [
                            scheme.primary.withValues(alpha: 0.7),
                            scheme.secondary.withValues(alpha: 0.7),
                          ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: scheme.primary.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  model.supportsImage
                      ? Icons.image_outlined
                      : Icons.chat_outlined,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      model.displayName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      model.sizeDisplay,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.6),
                          ),
                    ),
                  ],
                ),
              ),
              if (isActive && isLoading)
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else if (isActive)
                Icon(Icons.check_circle_rounded,
                    color: scheme.primary, size: 24)
              else
                Icon(
                  unavailable
                      ? Icons.block_rounded
                      : Icons.download_rounded,
                  color: unavailable
                      ? scheme.error
                      : scheme.onSurface.withValues(alpha: 0.55),
                  size: 22,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            model.description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.75),
                  height: 1.4,
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (model.supportsImage)
                _GlassChip('Multimodal', Icons.image_outlined),
              if (model.supportsThinking)
                _GlassChip('Thinking', Icons.psychology_outlined),
              if (unavailable)
                _GlassChip('Not available', Icons.block_outlined,
                    isError: true),
            ],
          ),
        ],
      ),
    );
  }
}

class _GlassChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isError;

  const _GlassChip(this.label, this.icon, {this.isError = false});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = isError ? scheme.error : scheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
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
