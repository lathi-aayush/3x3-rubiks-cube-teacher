import 'package:flutter/material.dart';
import '../../../domain/models/move.dart';

/// Drives smooth move animations for the 3D CubeRenderer.
class CubeAnimatorController extends ChangeNotifier {
  final TickerProvider vsync;
  late final AnimationController _controller;
  late final Animation<double> _animation;

  Move? _activeMove;
  final List<Move> _moveQueue = [];
  Duration _moveDuration;
  void Function(Move move)? onMoveApplied;
  VoidCallback? onSequenceCompleted;

  CubeAnimatorController({
    required this.vsync,
    Duration moveDuration = const Duration(milliseconds: 320),
    this.onMoveApplied,
    this.onSequenceCompleted,
  }) : _moveDuration = moveDuration {
    _controller = AnimationController(vsync: vsync, duration: _moveDuration);
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );

    _animation.addListener(notifyListeners);

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        final finishedMove = _activeMove;
        _activeMove = null;
        _controller.reset();

        if (finishedMove != null) {
          onMoveApplied?.call(finishedMove);
        }

        if (_moveQueue.isNotEmpty) {
          _activeMove = _moveQueue.removeAt(0);
          _controller.duration = _moveDuration;
          _controller.forward();
        } else {
          onSequenceCompleted?.call();
          notifyListeners();
        }
      }
    });
  }

  Move? get activeMove => _activeMove;
  double get progress => _animation.value;
  bool get isAnimating => _controller.isAnimating;
  int get queueLength => _moveQueue.length;

  /// Sets the animation duration for individual move turns.
  void setDuration(Duration duration) {
    _moveDuration = duration;
    _controller.duration = duration;
  }

  /// Plays a single move with a smooth rotation animation.
  void animateMove(Move move, {Duration? duration}) {
    if (duration != null) {
      _controller.duration = duration;
    } else {
      _controller.duration = _moveDuration;
    }

    if (isAnimating) {
      _moveQueue.add(move);
    } else {
      _activeMove = move;
      _controller.forward(from: 0.0);
    }
  }

  /// Queues a sequence of moves to be executed sequentially with animations.
  void animateSequence(List<Move> moves, {Duration? perMoveDuration}) {
    if (moves.isEmpty) return;

    if (perMoveDuration != null) {
      setDuration(perMoveDuration);
    }

    for (final m in moves) {
      if (!isAnimating && _activeMove == null) {
        _activeMove = m;
        _controller.forward(from: 0.0);
      } else {
        _moveQueue.add(m);
      }
    }
  }

  /// Immediately cancels animations and clears the queue.
  void stop() {
    _moveQueue.clear();
    _activeMove = null;
    _controller.stop();
    _controller.reset();
    notifyListeners();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
