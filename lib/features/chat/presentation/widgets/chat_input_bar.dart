import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ChatInputBar extends StatefulWidget {
  final bool isStreaming;
  final bool supportsImage;
  final void Function(String text, Uint8List? image) onSend;
  final VoidCallback onStop;

  const ChatInputBar({
    super.key,
    required this.isStreaming,
    required this.onSend,
    required this.onStop,
    this.supportsImage = false,
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final _controller = TextEditingController();
  Uint8List? _pendingImage;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final hasText = _controller.text.trim().isNotEmpty;
      if (hasText != _hasText) setState(() => _hasText = hasText);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      imageQuality: 85,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() => _pendingImage = bytes);
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty && _pendingImage == null) return;
    widget.onSend(text, _pendingImage);
    _controller.clear();
    setState(() => _pendingImage = null);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canSend = _hasText || _pendingImage != null;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                color: (isDark ? Colors.white : Colors.white)
                    .withValues(alpha: isDark ? 0.10 : 0.5),
                border: Border.all(
                  color: Colors.white
                      .withValues(alpha: isDark ? 0.15 : 0.55),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black
                        .withValues(alpha: isDark ? 0.32 : 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_pendingImage != null)
                    _ImagePreview(
                      bytes: _pendingImage!,
                      onRemove: () => setState(() => _pendingImage = null),
                    ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (widget.supportsImage)
                        IconButton(
                          icon: const Icon(Icons.image_outlined),
                          color: scheme.onSurface.withValues(alpha: 0.75),
                          onPressed:
                              widget.isStreaming ? null : _pickImage,
                          tooltip: 'Attach image',
                        ),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          minLines: 1,
                          maxLines: 5,
                          textCapitalization:
                              TextCapitalization.sentences,
                          enabled: !widget.isStreaming,
                          style: TextStyle(
                            color: scheme.onSurface,
                            fontSize: 15,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Message…',
                            hintStyle: TextStyle(
                              color: scheme.onSurface
                                  .withValues(alpha: 0.45),
                            ),
                            filled: false,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 14),
                          ),
                          onSubmitted: (_) => _send(),
                        ),
                      ),
                      const SizedBox(width: 4),
                      _SendButton(
                        streaming: widget.isStreaming,
                        canSend: canSend,
                        onSend: _send,
                        onStop: widget.onStop,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  final bool streaming;
  final bool canSend;
  final VoidCallback onSend;
  final VoidCallback onStop;

  const _SendButton({
    required this.streaming,
    required this.canSend,
    required this.onSend,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = streaming || canSend;

    return GestureDetector(
      onTap: enabled ? (streaming ? onStop : onSend) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 42,
        height: 42,
        margin: const EdgeInsets.only(right: 4, bottom: 4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: enabled
              ? LinearGradient(
                  colors: [scheme.primary, scheme.tertiary],
                )
              : null,
          color: enabled
              ? null
              : scheme.onSurface.withValues(alpha: 0.12),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: 0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Icon(
          streaming
              ? Icons.stop_rounded
              : Icons.arrow_upward_rounded,
          color: enabled
              ? Colors.white
              : scheme.onSurface.withValues(alpha: 0.4),
          size: 20,
        ),
      ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  final Uint8List bytes;
  final VoidCallback onRemove;

  const _ImagePreview({required this.bytes, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 4),
      child: Stack(
        alignment: Alignment.topRight,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.memory(bytes, height: 80, fit: BoxFit.cover),
          ),
          Padding(
            padding: const EdgeInsets.all(4),
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.65),
                ),
                child: const Icon(Icons.close_rounded,
                    size: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
