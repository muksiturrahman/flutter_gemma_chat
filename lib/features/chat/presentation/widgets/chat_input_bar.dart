import 'dart:typed_data';
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
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_pendingImage != null) _ImagePreview(
              bytes: _pendingImage!,
              onRemove: () => setState(() => _pendingImage = null),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (widget.supportsImage)
                  IconButton(
                    icon: const Icon(Icons.image_outlined),
                    onPressed: widget.isStreaming ? null : _pickImage,
                    tooltip: 'Attach image',
                  ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    minLines: 1,
                    maxLines: 5,
                    textCapitalization: TextCapitalization.sentences,
                    enabled: !widget.isStreaming,
                    decoration: const InputDecoration(
                      hintText: 'Message…',
                      filled: true,
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                widget.isStreaming
                    ? IconButton.filled(
                        onPressed: widget.onStop,
                        icon: const Icon(Icons.stop_rounded),
                        tooltip: 'Stop',
                      )
                    : IconButton.filled(
                        onPressed:
                            (_hasText || _pendingImage != null) ? _send : null,
                        icon: const Icon(Icons.send_rounded),
                        tooltip: 'Send',
                      ),
              ],
            ),
          ],
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
      padding: const EdgeInsets.only(bottom: 6),
      child: Stack(
        alignment: Alignment.topRight,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(bytes, height: 80, fit: BoxFit.cover),
          ),
          GestureDetector(
            onTap: onRemove,
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black54,
              ),
              child: const Icon(Icons.close, size: 18, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
