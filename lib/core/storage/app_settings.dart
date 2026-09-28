import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Device-local settings supplied by the student themselves.
///
/// Nothing secret lives in the app binary: each student pastes their own
/// Groq API key, and their Codeforces handle is only known locally until
/// they change it.
class AppSettings {
  AppSettings._({SharedPreferences? prefs}) : _prefs = prefs;

  static const String keyGroqApiKey = 'settings.groq_api_key';
  static const String keyGroqModel = 'settings.groq_model';
  static const String keyHandle = 'settings.codeforces_handle';

  /// Used when the student has not picked a model of their own.
  static const String defaultGroqModel = 'qwen/qwen3.8-27b';

  static AppSettings? _instance;

  /// Safe before [init] runs (widget tests, early startup): values then live
  /// in memory for the lifetime of the process instead of on disk.
  static AppSettings get instance => _instance ??= AppSettings._();

  /// Swaps in real persistence. Call once, before `runApp`.
  static Future<void> init() async {
    _instance = AppSettings._(prefs: await SharedPreferences.getInstance());
  }

  @visibleForTesting
  static void debugReset() => _instance = null;

  final SharedPreferences? _prefs;
  final Map<String, String> _memory = <String, String>{};

  String _read(String key) {
    final prefs = _prefs;
    if (prefs != null) return prefs.getString(key) ?? '';
    return _memory[key] ?? '';
  }

  Future<void> _write(String key, String value) async {
    final prefs = _prefs;
    if (prefs != null) {
      await prefs.setString(key, value);
      return;
    }
    _memory[key] = value;
  }

  // ── Groq ────────────────────────────────────────────────────────────────

  String get groqApiKey => _read(keyGroqApiKey).trim();

  bool get hasGroqApiKey => groqApiKey.isNotEmpty;

  Future<void> setGroqApiKey(String value) =>
      _write(keyGroqApiKey, value.trim());

  String get groqModel {
    final model = _read(keyGroqModel).trim();
    return model.isEmpty ? defaultGroqModel : model;
  }

  Future<void> setGroqModel(String value) => _write(keyGroqModel, value.trim());

  // ── Codeforces ──────────────────────────────────────────────────────────

  String get codeforcesHandle => _read(keyHandle).trim();

  bool get hasCodeforcesHandle => codeforcesHandle.isNotEmpty;

  Future<void> setCodeforcesHandle(String value) =>
      _write(keyHandle, value.trim());
}
