import 'dart:ui';
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
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      backgroundColor: Colors.transparent,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
          child: Container(
            decoration: BoxDecoration(
              color: (isDark ? Colors.black : Colors.white)
                  .withValues(alpha: isDark ? 0.32 : 0.45),
              border: Border(
                right: BorderSide(
                  color: Colors.white.withValues(alpha: isDark ? 0.10 : 0.45),
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  _DrawerHeader(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: FilledButton.icon(
                      onPressed: () => _newChat(context, ref),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('New Chat'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Conversations'.toUpperCase(),
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(
                              color:
                                  scheme.onSurface.withValues(alpha: 0.55),
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: threads.isEmpty
                        ? Center(
                            child: Text(
                              'No conversations yet',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: scheme.onSurface
                                        .withValues(alpha: 0.5),
                                  ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            itemCount: threads.length,
                            itemBuilder: (context, i) => _ThreadTile(
                              thread: threads[i],
                              isActive: threads[i].id == activeId,
                              onTap: () =>
                                  _openThread(context, ref, threads[i].id),
                              onRename: () =>
                                  _renameDialog(context, ref, threads[i]),
                              onDelete: () =>
                                  _deleteConfirm(context, ref, threads[i]),
                            ),
                          ),
                  ),
                  Divider(
                      height: 1,
                      color: Colors.white.withValues(alpha: 0.15)),
                  _FooterTile(
                    icon: Icons.storage_outlined,
                    label: 'Change Model',
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/models');
                    },
                  ),
                  _FooterTile(
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/settings');
                    },
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _newChat(BuildContext context, WidgetRef ref) async {
    final modelId = ref.read(activeModelIdProvider) ?? 'gemma-4-e2b-it';
    final thread =
        await ref.read(threadListProvider.notifier).createThread(modelId);
    ref.read(activeThreadIdProvider.notifier).set(thread.id);
    if (context.mounted) Navigator.pop(context);
  }

  void _openThread(BuildContext context, WidgetRef ref, String id) {
    ref.read(activeThreadIdProvider.notifier).set(id);
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
        ref.read(activeThreadIdProvider.notifier).set(null);
      }
    }
  }
}

class _DrawerHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  scheme.primary,
                  scheme.tertiary,
                ],
              ),
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                size: 22, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Gemma Chat',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                'On-device AI',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.6),
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FooterTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _FooterTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 14),
              Text(label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      )),
            ],
          ),
        ),
      ),
    );
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
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: isActive
                  ? scheme.primary.withValues(alpha: isDark ? 0.22 : 0.18)
                  : Colors.transparent,
              border: isActive
                  ? Border.all(
                      color: scheme.primary.withValues(alpha: 0.35),
                      width: 1,
                    )
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.chat_bubble_rounded,
                  color: isActive
                      ? scheme.primary
                      : scheme.onSurface.withValues(alpha: 0.6),
                  size: 18,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        thread.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isActive
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
                      ),
                      if (thread.preview.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          thread.preview,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: scheme.onSurface
                                    .withValues(alpha: 0.55),
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_horiz,
                    size: 18,
                    color: scheme.onSurface.withValues(alpha: 0.55),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                        value: 'rename', child: Text('Rename')),
                    const PopupMenuItem(
                        value: 'delete', child: Text('Delete')),
                  ],
                  onSelected: (v) {
                    if (v == 'rename') onRename();
                    if (v == 'delete') onDelete();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
