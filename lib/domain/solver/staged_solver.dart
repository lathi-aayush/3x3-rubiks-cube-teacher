import '../cube/facelets.dart';
import '../detection/stage_detector.dart';
import '../models/stage.dart';
import '../models/step.dart';
import 'corner_solver.dart';
import 'cross_solver.dart';
import 'edge_solver.dart';
import 'last_layer_solver.dart';

class StagedSolver {
  /// Synchronous solver entry point.
  static List<Step> solveSync(Facelets facelets, Stage stage) {
    if (StageDetector.isComplete(facelets, stage)) {
      return const [];
    }

    switch (stage) {
      case Stage.whiteCross:
        return CrossSolver.solve(facelets);
      case Stage.whiteCorners:
        return CornerSolver.solve(facelets);
      case Stage.middleEdges:
        return EdgeSolver.solve(facelets);
      case Stage.yellowCross:
        return LastLayerSolver.solveYellowCross(facelets);
      case Stage.orientCorners:
        return LastLayerSolver.solveOrientCorners(facelets);
      case Stage.permuteCorners:
        return LastLayerSolver.solvePermuteCorners(facelets);
      case Stage.permuteEdges:
        return LastLayerSolver.solvePermuteEdges(facelets);
    }
  }

  /// Asynchronous isolate-safe entry point (can be dispatched via compute()).
  static Future<List<Step>> solve(Facelets facelets, Stage stage) async {
    // Pure computation, directly callable or via compute()
    return solveSync(facelets, stage);
  }
}
