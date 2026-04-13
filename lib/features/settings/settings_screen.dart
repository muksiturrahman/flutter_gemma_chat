import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model_management/providers/model_install_provider.dart';

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
    await repo.setThemeModeIndex(_themeIdx);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved — reload the model to apply backend changes.'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Save'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionHeader('Inference'),
          _SettingCard(
            title: 'Backend',
            subtitle: 'GPU is faster on supported devices. CPU is more compatible.',
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 1, label: Text('GPU'), icon: Icon(Icons.memory)),
                ButtonSegment(value: 0, label: Text('CPU'), icon: Icon(Icons.computer)),
              ],
              selected: {_backendIdx},
              onSelectionChanged: (s) => setState(() => _backendIdx = s.first),
            ),
          ),
          const SizedBox(height: 8),
          _SettingCard(
            title: 'Max context tokens: $_maxTokens',
            subtitle: 'Larger context = longer memory but slower inference.',
            child: Slider(
              value: _maxTokens.toDouble(),
              min: 512,
              max: 4096,
              divisions: 7,
              label: '$_maxTokens',
              onChanged: (v) => setState(() => _maxTokens = v.round()),
            ),
          ),
          const SizedBox(height: 16),
          _SectionHeader('Appearance'),
          _SettingCard(
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
              onSelectionChanged: (s) => setState(() => _themeIdx = s.first),
            ),
          ),
          const SizedBox(height: 24),
          _SectionHeader('About'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('flutter_gemma'),
            subtitle: const Text('v0.13.2 — On-device Gemma inference'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.auto_awesome_outlined),
            title: const Text('Gemma 4 E2B'),
            subtitle: const Text(
                'Google\'s latest edge model — text + image, thinking mode'),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              letterSpacing: 1.2,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

class _SettingCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;

  const _SettingCard({
    required this.title,
    this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
            ],
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
