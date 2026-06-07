import 'dart:ui';
import 'package:flutter/material.dart';

/// Collapsible panel showing Gemma 4's internal thinking text.
class ThinkingIndicator extends StatefulWidget {
  final String thinkingText;
  final bool isStreaming;

  const ThinkingIndicator({
    super.key,
    required this.thinkingText,
    this.isStreaming = false,
  });

  @override
  State<ThinkingIndicator> createState() => _ThinkingIndicatorState();
}

class _ThinkingIndicatorState extends State<ThinkingIndicator> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = BorderRadius.circular(14);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: radius,
              color: scheme.secondary.withValues(alpha: isDark ? 0.18 : 0.14),
              border: Border.all(
                color: scheme.secondary.withValues(alpha: 0.35),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () => setState(() => _expanded = !_expanded),
                  borderRadius: radius,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        if (widget.isStreaming)
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: scheme.secondary,
                            ),
                          )
                        else
                          Icon(Icons.psychology_rounded,
                              size: 16, color: scheme.secondary),
                        const SizedBox(width: 8),
                        Text(
                          widget.isStreaming
                              ? 'Thinking…'
                              : 'Thought process',
                          style: Theme.of(context)
                              .textTheme
                              .labelMedium
                              ?.copyWith(
                                color: scheme.onSurface
                                    .withValues(alpha: 0.75),
                                fontStyle: FontStyle.italic,
                              ),
                        ),
                        const Spacer(),
                        Icon(
                          _expanded
                              ? Icons.expand_less_rounded
                              : Icons.expand_more_rounded,
                          size: 18,
                          color: scheme.onSurface.withValues(alpha: 0.65),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_expanded)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: Text(
                      widget.thinkingText,
                      style:
                          Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: scheme.onSurface
                                    .withValues(alpha: 0.75),
                                fontStyle: FontStyle.italic,
                                height: 1.4,
                              ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
