import 'dart:typed_data';
import 'package:hive_ce/hive.dart';

part 'chat_message.g.dart';

@HiveType(typeId: 1)
class ChatMessage extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String role; // 'user' | 'assistant'

  @HiveField(2)
  String text;

  @HiveField(3)
  final DateTime timestamp;

  @HiveField(4)
  Uint8List? imageBytes;

  @HiveField(5)
  String? thinkingText; // Gemma 4 thinking content

  ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.timestamp,
    this.imageBytes,
    this.thinkingText,
  });

  bool get isUser => role == 'user';
  bool get hasImage => imageBytes != null && imageBytes!.isNotEmpty;

  ChatMessage copyWith({String? text, String? thinkingText}) {
    return ChatMessage(
      id: id,
      role: role,
      text: text ?? this.text,
      timestamp: timestamp,
      imageBytes: imageBytes,
      thinkingText: thinkingText ?? this.thinkingText,
    );
  }
}
