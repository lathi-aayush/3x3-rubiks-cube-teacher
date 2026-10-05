import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/models/session.dart';

class SessionRepository {
  static const String _currentSessionKey = 'rubiks_current_session';

  final SharedPreferences _prefs;

  SessionRepository(this._prefs);

  static Future<SessionRepository> create() async {
    final prefs = await SharedPreferences.getInstance();
    return SessionRepository(prefs);
  }

  /// Saves the active teaching/learning session.
  Future<void> saveCurrentSession(Session session) async {
    final jsonStr = jsonEncode(session.toJson());
    await _prefs.setString(_currentSessionKey, jsonStr);
  }

  /// Loads the active session if one exists.
  Session? loadCurrentSession() {
    final jsonStr = _prefs.getString(_currentSessionKey);
    if (jsonStr == null || jsonStr.isEmpty) return null;
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return Session.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  /// Clears the active session.
  Future<void> clearCurrentSession() async {
    await _prefs.remove(_currentSessionKey);
  }

  /// Checks if an active session exists.
  bool hasActiveSession() {
    return _prefs.containsKey(_currentSessionKey);
  }
}
