import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../../data/models/chat_message.dart';
import 'thinking_indicator.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isUser) ...[
            _Avatar(isUser: false),
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
            _Avatar(isUser: true),
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
    final colorScheme = Theme.of(context).colorScheme;
    final isUser = message.isUser;

    final bgColor =
        isUser ? colorScheme.primary : colorScheme.surfaceContainerHigh;
    final fgColor =
        isUser ? colorScheme.onPrimary : colorScheme.onSurface;

    return GestureDetector(
      onLongPress: () => _copyToClipboard(context, message.text),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.hasImage)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.memory(
                  message.imageBytes!,
                  width: 220,
                  fit: BoxFit.cover,
                ),
              ),
            if (message.hasImage && message.text.isNotEmpty)
              const SizedBox(height: 6),
            if (message.text.isNotEmpty)
              isUser
                  ? Text(message.text, style: TextStyle(color: fgColor))
                  : MarkdownBody(
                      data: message.text,
                      styleSheet: MarkdownStyleSheet.fromTheme(
                        Theme.of(context),
                      ).copyWith(
                        p: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: fgColor),
                        code: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontFamily: 'monospace',
                              backgroundColor:
                                  colorScheme.surfaceContainerHighest,
                            ),
                      ),
                    ),
          ],
        ),
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Copied to clipboard'),
          duration: Duration(seconds: 1)),
    );
  }
}

class _Avatar extends StatelessWidget {
  final bool isUser;
  const _Avatar({required this.isUser});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return CircleAvatar(
      radius: 14,
      backgroundColor: isUser
          ? colorScheme.primaryContainer
          : colorScheme.secondaryContainer,
      child: Icon(
        isUser ? Icons.person_outline : Icons.auto_awesome_outlined,
        size: 16,
        color: isUser
            ? colorScheme.onPrimaryContainer
            : colorScheme.onSecondaryContainer,
      ),
    );
  }
}
