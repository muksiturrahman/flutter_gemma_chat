import 'package:hive_ce/hive.dart';
import 'chat_message.dart';

part 'chat_thread.g.dart';

@HiveType(typeId: 0)
class ChatThread extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  final DateTime createdAt;

  @HiveField(3)
  DateTime updatedAt;

  @HiveField(4)
  String modelId;

  @HiveField(5)
  List<ChatMessage> messages;

  ChatThread({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.modelId,
    List<ChatMessage>? messages,
  }) : messages = messages ?? [];

  ChatMessage? get lastMessage =>
      messages.isEmpty ? null : messages.last;

  String get preview {
    final last = lastMessage;
    if (last == null) return 'New conversation';
    final text = last.text.trim();
    return text.length > 80 ? '${text.substring(0, 80)}…' : text;
  }
}
