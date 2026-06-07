import 'package:flutter_gemma/flutter_gemma.dart';
import '../models/gemma_model_info.dart';

const kModelRegistry = <GemmaModelInfo>[
  GemmaModelInfo(
    id: 'gemma-4-e2b-it',
    displayName: 'Gemma 4 E2B (Instruct)',
    description: 'Latest Gemma 4 edge model. Multimodal (text + image), '
        'supports thinking mode. Best balance of capability and speed.',
    sizeMb: 2700,
    // Files verified at:
    // https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm/tree/main
    // The repo only ships .litertlm (and a web-specific .task), so we use the
    // universal .litertlm on both mobile and desktop.
    mobileUrl:
        'https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm/resolve/main/gemma-4-E2B-it.litertlm',
    desktopUrl:
        'https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm/resolve/main/gemma-4-E2B-it.litertlm',
    supportsImage: true,
    supportsThinking: true,
    requiresAuth: true,
    modelType: ModelType.gemmaIt,
  ),
  GemmaModelInfo(
    id: 'gemma-3-1b-it',
    displayName: 'Gemma 3 1B (Instruct)',
    description: 'Compact and fast. Great for quick replies on any device. '
        'Text-only, ~530 MB.',
    sizeMb: 530,
    // Files verified at:
    // https://huggingface.co/litert-community/Gemma3-1B-IT/tree/main
    mobileUrl:
        'https://huggingface.co/litert-community/Gemma3-1B-IT/resolve/main/'
        'Gemma3-1B-IT_multi-prefill-seq_q4_ekv2048.task',
    desktopUrl:
        'https://huggingface.co/litert-community/Gemma3-1B-IT/resolve/main/'
        'gemma3-1b-it-int4.litertlm',
    supportsImage: false,
    supportsThinking: false,
    requiresAuth: true,
    modelType: ModelType.gemmaIt,
  ),
];

GemmaModelInfo? modelById(String id) {
  try {
    return kModelRegistry.firstWhere((m) => m.id == id);
  } catch (_) {
    return null;
  }
}
