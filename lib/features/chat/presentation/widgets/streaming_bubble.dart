import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../features/chat/providers/chat_session_provider.dart';
import 'thinking_indicator.dart';

/// A dedicated widget for the in-progress assistant response.
/// Only this widget rebuilds as tokens arrive — the rest of the list stays still.
class StreamingBubble extends StatelessWidget {
  final ChatStreamState streamState;

  const StreamingBubble({super.key, required this.streamState});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final radius = const BorderRadius.only(
      topLeft: Radius.circular(20),
      topRight: Radius.circular(20),
      bottomRight: Radius.circular(20),
      bottomLeft: Radius.circular(6),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [scheme.secondary, scheme.primary],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              size: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (streamState.thinkingText.isNotEmpty)
                  ThinkingIndicator(
                    thinkingText: streamState.thinkingText,
                    isStreaming: streamState.isThinking,
                  ),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.78,
                  ),
                  child: ClipRRect(
                    borderRadius: radius,
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          borderRadius: radius,
                          color: (isDark ? Colors.white : Colors.white)
                              .withValues(alpha: isDark ? 0.10 : 0.55),
                          border: Border.all(
                            color: Colors.white
                                .withValues(alpha: isDark ? 0.15 : 0.55),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black
                                  .withValues(alpha: isDark ? 0.25 : 0.06),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: streamState.streamingText.isEmpty
                            ? _TypingDots(color: scheme.primary)
                            : Text(
                                streamState.streamingText,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: scheme.onSurface,
                                      height: 1.4,
                                    ),
                              ),
                      ),
                    ),
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

class _TypingDots extends StatefulWidget {
  final Color color;
  const _TypingDots({required this.color});

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final step = (_controller.value * 3).floor();
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            return AnimatedOpacity(
              opacity: i == step ? 1.0 : 0.3,
              duration: const Duration(milliseconds: 150),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.color,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
