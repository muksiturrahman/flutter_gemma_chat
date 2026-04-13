import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/chat_thread.dart';
import '../providers/chat_session_provider.dart';
import '../../model_management/providers/model_install_provider.dart';

class ChatDrawer extends ConsumerWidget {
  const ChatDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final threads = ref.watch(threadListProvider);
    final activeId = ref.watch(activeThreadIdProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: colorScheme.primaryContainer),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.auto_awesome,
                    size: 32, color: colorScheme.onPrimaryContainer),
                const SizedBox(height: 8),
                Text(
                  'Gemma Chat',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'On-device AI',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onPrimaryContainer
                            .withValues(alpha: 0.7),
                      ),
                ),
              ],
            ),
          ),

          // New chat button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: FilledButton.icon(
              onPressed: () => _newChat(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('New Chat'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
              ),
            ),
          ),

          const Divider(height: 8),

          // Thread list
          Expanded(
            child: threads.isEmpty
                ? Center(
                    child: Text(
                      'No conversations yet',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.outline,
                          ),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: threads.length,
                    itemBuilder: (context, i) => _ThreadTile(
                      thread: threads[i],
                      isActive: threads[i].id == activeId,
                      onTap: () => _openThread(context, ref, threads[i].id),
                      onRename: () =>
                          _renameDialog(context, ref, threads[i]),
                      onDelete: () =>
                          _deleteConfirm(context, ref, threads[i]),
                    ),
                  ),
          ),

          const Divider(height: 8),

          // Settings & model picker
          ListTile(
            leading: const Icon(Icons.storage_outlined),
            title: const Text('Change Model'),
            onTap: () {
              Navigator.pop(context);
              context.go('/models');
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              context.push('/settings');
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<void> _newChat(BuildContext context, WidgetRef ref) async {
    final modelId = ref.read(activeModelIdProvider) ?? 'gemma-4-e2b-it';
    final thread =
        await ref.read(threadListProvider.notifier).createThread(modelId);
    ref.read(activeThreadIdProvider.notifier).state = thread.id;
    if (context.mounted) Navigator.pop(context);
  }

  void _openThread(BuildContext context, WidgetRef ref, String id) {
    ref.read(activeThreadIdProvider.notifier).state = id;
    Navigator.pop(context);
  }

  Future<void> _renameDialog(
      BuildContext context, WidgetRef ref, ChatThread thread) async {
    final controller = TextEditingController(text: thread.title);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration:
              const InputDecoration(hintText: 'Conversation title'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () =>
                  Navigator.pop(ctx, controller.text.trim()),
              child: const Text('Rename')),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      await ref
          .read(threadListProvider.notifier)
          .renameThread(thread.id, result);
    }
  }

  Future<void> _deleteConfirm(
      BuildContext context, WidgetRef ref, ChatThread thread) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Chat'),
        content: Text('Delete "${thread.title}"? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true) {
      final activeId = ref.read(activeThreadIdProvider);
      await ref
          .read(threadListProvider.notifier)
          .deleteThread(thread.id);
      if (activeId == thread.id) {
        ref.read(activeThreadIdProvider.notifier).state = null;
      }
    }
  }
}

class _ThreadTile extends StatelessWidget {
  final ChatThread thread;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  const _ThreadTile({
    required this.thread,
    required this.isActive,
    required this.onTap,
    required this.onRename,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      selected: isActive,
      selectedTileColor: colorScheme.primaryContainer.withValues(alpha: 0.4),
      leading: Icon(
        Icons.chat_bubble_outline,
        color: isActive ? colorScheme.primary : colorScheme.onSurfaceVariant,
        size: 20,
      ),
      title: Text(
        thread.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        thread.preview,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, size: 18),
        itemBuilder: (_) => [
          const PopupMenuItem(value: 'rename', child: Text('Rename')),
          const PopupMenuItem(value: 'delete', child: Text('Delete')),
        ],
        onSelected: (v) {
          if (v == 'rename') onRename();
          if (v == 'delete') onDelete();
        },
      ),
      onTap: onTap,
    );
  }
}
