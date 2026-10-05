import 'dart:async';
import 'package:flutter/foundation.dart';
import '../data/session_repository.dart';
import '../domain/models/session.dart';

class SessionProvider extends ChangeNotifier {
  final SessionRepository _repository;

  Timer? _timer;
  int _elapsedSeconds = 0;
  int get elapsedSeconds => _elapsedSeconds;

  bool _isRunning = false;
  bool get isRunning => _isRunning;

  Session? get currentSession => _repository.loadCurrentSession();
  bool get hasActiveSession => _repository.hasActiveSession();

  SessionProvider(this._repository);

  void startTimer() {
    _timer?.cancel();
    _isRunning = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsedSeconds++;
      notifyListeners();
    });
  }

  void pauseTimer() {
    _timer?.cancel();
    _isRunning = false;
    notifyListeners();
  }

  void resetTimer() {
    _timer?.cancel();
    _elapsedSeconds = 0;
    _isRunning = false;
    notifyListeners();
  }

  Future<void> clearSession() async {
    resetTimer();
    await _repository.clearCurrentSession();
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
