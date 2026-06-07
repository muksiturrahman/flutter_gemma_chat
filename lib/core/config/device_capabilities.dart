import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';

/// Detects whether the GPU (OpenCL) inference backend can be safely used.
///
/// On Android/iOS emulators there is no OpenCL library, and flutter_gemma's
/// native LiteRT engine crashes the whole process with a SIGSEGV when it tries
/// to initialize on the GPU — a native crash that Dart `try/catch` cannot
/// recover from. So on emulators we must force the CPU backend up front.
class DeviceCapabilities {
  DeviceCapabilities._();

  static bool? _isPhysicalDevice;

  /// True on real hardware, false on an emulator/simulator. Cached after the
  /// first call. Desktop/web are treated as physical (they don't hit the
  /// OpenCL-emulator problem).
  static Future<bool> isPhysicalDevice() async {
    if (_isPhysicalDevice != null) return _isPhysicalDevice!;

    bool result = true;
    try {
      final info = DeviceInfoPlugin();
      if (defaultTargetPlatform == TargetPlatform.android) {
        result = (await info.androidInfo).isPhysicalDevice;
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        result = (await info.iosInfo).isPhysicalDevice;
      }
    } catch (_) {
      result = true; // If detection fails, don't override the user's choice.
    }

    _isPhysicalDevice = result;
    return result;
  }

  /// Whether it is safe to honor a GPU backend preference.
  static Future<bool> get canUseGpu async => isPhysicalDevice();
}
