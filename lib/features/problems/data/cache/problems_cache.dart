import 'dart:convert';

import 'package:fawateery/features/problems/data/models/problem_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Keeps the problemset and fetched statements on the device, so the list
/// loads instantly and a read problem can be re-read without a connection.
class ProblemsCache {
  const ProblemsCache();

  static const String _problemsKey = 'problems.cache.v1';
  static const String _statementKeyPrefix = 'problems.statement.';
  static const String _statementIndexKey = 'problems.statement.index';

  /// Small on purpose: statements are tens of kilobytes each.
  static const int maxCachedStatements = 12;

  Future<List<Map<String, dynamic>>?> readProblems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_problemsKey);
      if (raw == null || raw.isEmpty) return null;

      final decoded = jsonDecode(raw);
      if (decoded is! List) return null;

      return decoded
          .whereType<Map<String, dynamic>>()
          .toList(growable: false);
    } catch (_) {
      // A cache problem must never break the screen.
      return null;
    }
  }

  Future<void> writeProblems(List<ProblemRef> problems) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded =
          jsonEncode(problems.map((problem) => problem.toJson()).toList());
      await prefs.setString(_problemsKey, encoded);
    } catch (_) {
      // Ignored: the next successful fetch will try again.
    }
  }

  Future<String?> readStatement(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('$_statementKeyPrefix$id');
    } catch (_) {
      return null;
    }
  }

  Future<void> writeStatement(String id, String html) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_statementKeyPrefix$id', html);

      final index = prefs.getStringList(_statementIndexKey) ?? <String>[];
      index.remove(id);
      index.insert(0, id);

      while (index.length > maxCachedStatements) {
        final evicted = index.removeLast();
        await prefs.remove('$_statementKeyPrefix$evicted');
      }

      await prefs.setStringList(_statementIndexKey, index);
    } catch (_) {
      // Ignored: caching is best-effort.
    }
  }

  Future<void> clearStatements() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final index = prefs.getStringList(_statementIndexKey) ?? <String>[];
      for (final id in index) {
        await prefs.remove('$_statementKeyPrefix$id');
      }
      await prefs.remove(_statementIndexKey);
    } catch (_) {
      // Ignored: caching is best-effort.
    }
  }
}
