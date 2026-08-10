import 'dart:io';

class ReleaseLogger {
  static File? _file;
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    try {
      _file = File('/sdcard/Download/release_debug.log');
      await _file!.writeAsString(
        '=== Release Logger Init: ${DateTime.now()} ===\n',
      );
      _initialized = true;
    } catch (_) {}
  }

  static Future<void> log(String tag, String message) async {
    try {
      if (!_initialized) await init();
      final line = '[${DateTime.now()}][$tag] $message\n';
      await _file?.writeAsString(line, mode: FileMode.append);
    } catch (_) {}
  }

  static Future<String> readLogs() async {
    try {
      return await _file?.readAsString() ?? '(no logs)';
    } catch (_) {
      return '(error reading logs)';
    }
  }

  static String? get filePath => _file?.path;
}
