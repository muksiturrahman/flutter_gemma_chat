import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/widgets/glass_container.dart';
import '../model_management/providers/model_install_provider.dart';
import 'providers/settings_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late int _backendIdx;
  late int _maxTokens;
  late int _themeIdx;

  @override
  void initState() {
    super.initState();
    final repo = ref.read(modelRepositoryProvider);
    _backendIdx = repo.preferredBackendIndex;
    _maxTokens = repo.maxTokens;
    _themeIdx = repo.themeModeIndex;
  }

  Future<void> _save() async {
    final repo = ref.read(modelRepositoryProvider);
    await repo.setPreferredBackendIndex(_backendIdx);
    await repo.setMaxTokens(_maxTokens);
    // Theme goes through its notifier so the change rebuilds the app instantly.
    await ref.read(themeModeProvider.notifier).setIndex(_themeIdx);
    // Explicitly choosing GPU is an opt-in to retry it, even if it crashed
    // before. Crash recovery will disable it again if it still fails.
    if (_backendIdx != 0) {
      await repo.setGpuKnownBad(false);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Settings saved — reload the model to apply backend changes.'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: _GlassAppBar(
        title: 'Settings',
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: _save,
              child: const Text('Save'),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 96, 16, 24),
        children: [
          const _SectionHeader('Inference'),
          GlassCard(
            child: _Setting(
              title: 'Backend',
              subtitle:
                  'GPU is faster on supported devices. CPU is more compatible.',
              child: SegmentedButton<int>(
                segments: const [
                  ButtonSegment(
                      value: 1, label: Text('GPU'), icon: Icon(Icons.memory)),
                  ButtonSegment(
                      value: 0,
                      label: Text('CPU'),
                      icon: Icon(Icons.computer)),
                ],
                selected: {_backendIdx},
                onSelectionChanged: (s) =>
                    setState(() => _backendIdx = s.first),
              ),
            ),
          ),
          const SizedBox(height: 10),
          GlassCard(
            child: _Setting(
              title: 'Max context tokens: $_maxTokens',
              subtitle:
                  'Larger context = longer memory but slower inference.',
              child: Slider(
                value: _maxTokens.toDouble(),
                min: 512,
                max: 4096,
                divisions: 7,
                label: '$_maxTokens',
                onChanged: (v) => setState(() => _maxTokens = v.round()),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const _SectionHeader('Appearance'),
          GlassCard(
            child: _Setting(
              title: 'Theme',
              child: SegmentedButton<int>(
                segments: const [
                  ButtonSegment(
                      value: 0,
                      label: Text('System'),
                      icon: Icon(Icons.brightness_auto)),
                  ButtonSegment(
                      value: 1,
                      label: Text('Light'),
                      icon: Icon(Icons.light_mode)),
                  ButtonSegment(
                      value: 2,
                      label: Text('Dark'),
                      icon: Icon(Icons.dark_mode)),
                ],
                selected: {_themeIdx},
                onSelectionChanged: (s) =>
                    setState(() => _themeIdx = s.first),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const _SectionHeader('About'),
          GlassCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _AboutTile(
                  icon: Icons.info_outline,
                  title: 'flutter_gemma',
                  subtitle: 'v0.13.2 — On-device Gemma inference',
                ),
                Divider(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.12),
                ),
                _AboutTile(
                  icon: Icons.auto_awesome_outlined,
                  title: 'Gemma 4 E2B',
                  subtitle:
                      "Google's latest edge model — text + image, thinking mode",
                ),
              ],
            ),
          ),
        ],
      ),
    );
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

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 10),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: scheme.primary,
              letterSpacing: 1.4,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _Setting extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;

  const _Setting({
    required this.title,
    this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.6),
                ),
          ),
        ],
        const SizedBox(height: 14),
        child,
      ],
    );
  }
}

class _AboutTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _AboutTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: scheme.primary, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        )),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.6),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
