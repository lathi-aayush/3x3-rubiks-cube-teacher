import 'package:flutter/foundation.dart';
import '../data/session_repository.dart';
import '../domain/cube/facelets.dart';
import '../domain/cube/move_applier.dart';
import '../domain/detection/stage_detector.dart';
import '../domain/models/move.dart';
import '../domain/models/session.dart';
import '../domain/models/stage.dart';
import '../domain/models/step.dart';
import '../domain/solver/staged_solver.dart';

class TeachingProvider extends ChangeNotifier {
  final SessionRepository _sessionRepository;

  Facelets _cubeState = FaceletConstants.createSolved();
  Facelets get cubeState => List.unmodifiable(_cubeState);

  Stage? _currentStage;
  Stage? get currentStage => _currentStage;

  List<Step> _currentSteps = [];
  List<Step> get currentSteps => List.unmodifiable(_currentSteps);

  int _currentStepIndex = 0;
  int get currentStepIndex => _currentStepIndex;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool get isCubeSolved => _currentStage == null && StageDetector.detect(_cubeState) == null;
  bool get hasSteps => _currentSteps.isNotEmpty;
  Step? get currentStep => hasSteps && _currentStepIndex < _currentSteps.length ? _currentSteps[_currentStepIndex] : null;

  TeachingProvider(this._sessionRepository);

  /// Initializes learning session from a 54-integer scanned cube state.
  Future<void> startSession(Facelets initialFacelets) async {
    _isLoading = true;
    notifyListeners();

    _cubeState = List<int>.from(initialFacelets);
    _currentStage = StageDetector.detect(_cubeState);

    await _loadStepsForCurrentStage();

    _currentStepIndex = 0;
    _isLoading = false;
    _saveSession();
    notifyListeners();
  }

  /// Restores active session if available.
  Future<bool> restoreSession() async {
    final session = _sessionRepository.loadCurrentSession();
    if (session == null) return false;

    _isLoading = true;
    notifyListeners();

    _cubeState = List<int>.from(session.facelets);
    _currentStage = session.currentStage;
    _currentStepIndex = session.currentStepIndex;

    await _loadStepsForCurrentStage();

    _isLoading = false;
    notifyListeners();
    return true;
  }

  /// Executes the moves of the current step on the virtual cube and advances step.
  Future<void> advanceStep() async {
    if (!hasSteps) return;

    final step = currentStep;
    if (step != null) {
      _cubeState = MoveApplier.applyAll(_cubeState, step.moves);
    }

    if (_currentStepIndex + 1 < _currentSteps.length) {
      _currentStepIndex++;
    } else {
      // Current stage steps completed, advance to next incomplete stage
      _currentStage = StageDetector.detect(_cubeState);
      _currentStepIndex = 0;
      await _loadStepsForCurrentStage();
    }

    _saveSession();
    notifyListeners();
  }

  /// Steps backwards by 1 step.
  void previousStep() {
    if (_currentStepIndex > 0) {
      _currentStepIndex--;
      notifyListeners();
    }
  }

  /// Applies a single move interactively (e.g., from UI rotation button).
  void applyMove(Move move) {
    _cubeState = MoveApplier.apply(_cubeState, move);
    _currentStage = StageDetector.detect(_cubeState);
    _saveSession();
    notifyListeners();
  }

  Future<void> _loadStepsForCurrentStage() async {
    if (_currentStage == null) {
      _currentSteps = [];
      return;
    }

    try {
      _currentSteps = await StagedSolver.solve(_cubeState, _currentStage!);
    } catch (_) {
      // Synchronous fallback
      _currentSteps = StagedSolver.solveSync(_cubeState, _currentStage!);
    }
  }

  void _saveSession() {
    if (_currentStage == null) {
      _sessionRepository.clearCurrentSession();
    } else {
      final session = Session(
        facelets: _cubeState,
        currentStage: _currentStage!,
        currentStepIndex: _currentStepIndex,
        lastUpdated: DateTime.now(),
      );
      _sessionRepository.saveCurrentSession(session);
    }
  }
}
