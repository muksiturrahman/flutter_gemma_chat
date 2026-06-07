import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import '../../../../data/models/chat_message.dart';
import 'thinking_indicator.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isUser) ...[
            const _Avatar(isUser: false),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: message.isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (message.thinkingText != null &&
                    message.thinkingText!.isNotEmpty)
                  ThinkingIndicator(thinkingText: message.thinkingText!),
                _BubbleBody(message: message),
              ],
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            const _Avatar(isUser: true),
          ],
        ],
      ),
    );
  }
}

class _BubbleBody extends StatelessWidget {
  final ChatMessage message;

  const _BubbleBody({required this.message});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isUser = message.isUser;

    final radius = BorderRadius.only(
      topLeft: const Radius.circular(20),
      topRight: const Radius.circular(20),
      bottomLeft: Radius.circular(isUser ? 20 : 6),
      bottomRight: Radius.circular(isUser ? 6 : 20),
    );

    return GestureDetector(
      onLongPress: () => _copyToClipboard(context, message.text),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: radius,
                gradient: isUser
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          scheme.primary.withValues(alpha: 0.85),
                          scheme.tertiary.withValues(alpha: 0.85),
                        ],
                      )
                    : null,
                color: isUser
                    ? null
                    : (isDark ? Colors.white : Colors.white)
                        .withValues(alpha: isDark ? 0.10 : 0.55),
                border: Border.all(
                  color: isUser
                      ? Colors.white.withValues(alpha: 0.25)
                      : Colors.white.withValues(alpha: isDark ? 0.15 : 0.55),
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
              child: _BubbleContent(message: message, isUser: isUser),
            ),
          ),
        ),
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 1),
      ),
    );
  }
}

class _BubbleContent extends StatelessWidget {
  final ChatMessage message;
  final bool isUser;

  const _BubbleContent({required this.message, required this.isUser});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fgColor = isUser ? Colors.white : scheme.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (message.hasImage)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(
              message.imageBytes!,
              width: 220,
              fit: BoxFit.cover,
            ),
          ),
        if (message.hasImage && message.text.isNotEmpty)
          const SizedBox(height: 8),
        if (message.text.isNotEmpty)
          isUser
              ? Text(
                  message.text,
                  style: TextStyle(color: fgColor, fontSize: 15, height: 1.35),
                )
              : MarkdownBody(
                  data: message.text,
                  styleSheet:
                      MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                    p: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: fgColor,
                          height: 1.4,
                        ),
                    code: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                          backgroundColor:
                              Colors.black.withValues(alpha: 0.18),
                          color: fgColor,
                        ),
                    codeblockDecoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  final bool isUser;
  const _Avatar({required this.isUser});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: isUser
              ? [scheme.primary, scheme.tertiary]
              : [scheme.secondary, scheme.primary],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        isUser ? Icons.person_rounded : Icons.auto_awesome_rounded,
        size: 16,
        color: Colors.white,
      ),
    );
  }
}
