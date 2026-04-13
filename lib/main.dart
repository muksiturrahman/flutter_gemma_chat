import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'data/models/chat_thread.dart';
import 'data/models/chat_message.dart';
import 'data/repositories/chat_repository.dart';
import 'data/repositories/model_repository.dart';
import 'services/gemma_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Hive setup
  await Hive.initFlutter();
  Hive.registerAdapter(ChatThreadAdapter());
  Hive.registerAdapter(ChatMessageAdapter());
  await ChatRepository.openBox();
  await ModelRepository.openBox();

  // flutter_gemma initialization — wires up the service, no download
  const hfToken = String.fromEnvironment('HUGGINGFACE_TOKEN');
  await GemmaService.instance.initialize(
    huggingFaceToken: hfToken.isNotEmpty ? hfToken : null,
  );

  runApp(const ProviderScope(child: App()));
}
