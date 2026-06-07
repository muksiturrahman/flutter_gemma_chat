import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'data/models/chat_thread.dart';
import 'data/models/chat_message.dart';
import 'data/repositories/chat_repository.dart';
import 'data/repositories/model_repository.dart';
import 'services/gemma_service.dart';
import 'core/config/app_secrets.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Hive setup
  await Hive.initFlutter();
  Hive.registerAdapter(ChatThreadAdapter());
  Hive.registerAdapter(ChatMessageAdapter());
  await ChatRepository.openBox();
  await ModelRepository.openBox();

  // Load the HuggingFace token from lib/.env (or --dart-define).
  await AppSecrets.load();

  // flutter_gemma initialization — wires up the service, no download
  await GemmaService.instance.initialize(
    huggingFaceToken: AppSecrets.huggingFaceToken,
  );

  // Downloads only run with the screen open, so cancel any task WorkManager
  // auto-resumed from a previous session — a broken one would otherwise keep
  // resuming in the background and block fresh downloads at 0%.
  await GemmaService.instance.clearStaleDownloads();

  runApp(const ProviderScope(child: App()));
}
