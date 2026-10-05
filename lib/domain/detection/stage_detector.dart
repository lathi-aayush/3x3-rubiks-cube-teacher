import '../cube/facelets.dart';
import '../cube/piece_view.dart';
import '../models/stage.dart';

class StageDetector {
  /// Returns the first incomplete stage (1–7), or null if fully solved.
  static Stage? detect(Facelets facelets) {
    for (final stage in Stage.values) {
      if (!isComplete(facelets, stage)) {
        return stage;
      }
    }
    return null; // All 7 stages complete => solved!
  }

  /// Returns true if the given stage's completion condition is met.
  static bool isComplete(Facelets facelets, Stage stage) {
    final view = PieceView.from(facelets);
    final isWhiteOnU = facelets[4] == 0;

    switch (stage) {
      case Stage.whiteCross:
        return _isWhiteCrossComplete(view, isWhiteOnU);

      case Stage.whiteCorners:
        return _isWhiteCrossComplete(view, isWhiteOnU) &&
            _isWhiteCornersComplete(view, isWhiteOnU);

      case Stage.middleEdges:
        return isComplete(facelets, Stage.whiteCorners) &&
            _isMiddleEdgesComplete(view);

      case Stage.yellowCross:
        return isComplete(facelets, Stage.middleEdges) &&
            _isYellowCrossComplete(facelets, isWhiteOnU);

      case Stage.orientCorners:
        return isComplete(facelets, Stage.yellowCross) &&
            _isYellowCornersOriented(facelets, isWhiteOnU);

      case Stage.permuteCorners:
        return isComplete(facelets, Stage.orientCorners) &&
            _isYellowCornersPermuted(view, isWhiteOnU);

      case Stage.permuteEdges:
        return isComplete(facelets, Stage.permuteCorners) &&
            _isFullySolved(facelets);
    }
  }

  static bool _isWhiteCrossComplete(PieceView view, bool isWhiteOnU) {
    if (isWhiteOnU) {
      // White on U: UR(0), UF(1), UL(2), UB(3)
      for (int i = 0; i < 4; i++) {
        final edge = view.edges[i];
        if (edge.position != i || edge.orientation != 0) return false;
      }
      return true;
    } else {
      // White on D: DR(4), DF(5), DL(6), DB(7)
      for (int i = 4; i < 8; i++) {
        final edge = view.edges[i];
        if (edge.position != i || edge.orientation != 0) return false;
      }
      return true;
    }
  }

  static bool _isWhiteCornersComplete(PieceView view, bool isWhiteOnU) {
    if (isWhiteOnU) {
      // URF(0), ULF(1), ULB(2), URB(3)
      for (int i = 0; i < 4; i++) {
        final corner = view.corners[i];
        if (corner.position != i || corner.orientation != 0) return false;
      }
      return true;
    } else {
      // DRF(4), DLF(5), DLB(6), DRB(7)
      for (int i = 4; i < 8; i++) {
        final corner = view.corners[i];
        if (corner.position != i || corner.orientation != 0) return false;
      }
      return true;
    }
  }

  static bool _isMiddleEdgesComplete(PieceView view) {
    // Middle edges: FR(8), FL(9), BL(10), BR(11)
    for (int i = 8; i < 12; i++) {
      final edge = view.edges[i];
      if (edge.position != i || edge.orientation != 0) return false;
    }
    return true;
  }

  static bool _isYellowCrossComplete(Facelets facelets, bool isWhiteOnU) {
    if (isWhiteOnU) {
      // Yellow face is D (cells 27..35, center 31 is yellow=1)
      // Edges on D: DF(28), DL(30), DR(32), DB(34)
      return facelets[28] == 1 &&
          facelets[30] == 1 &&
          facelets[32] == 1 &&
          facelets[34] == 1;
    } else {
      // Yellow face is U (cells 0..8, center 4 is yellow=1)
      // Edges on U: UF(1), UL(3), UR(5), UB(7)
      return facelets[1] == 1 &&
          facelets[3] == 1 &&
          facelets[5] == 1 &&
          facelets[7] == 1;
    }
  }

  static bool _isYellowCornersOriented(Facelets facelets, bool isWhiteOnU) {
    if (isWhiteOnU) {
      for (int i = 27; i <= 35; i++) {
        if (facelets[i] != 1) return false;
      }
      return true;
    } else {
      for (int i = 0; i <= 8; i++) {
        if (facelets[i] != 1) return false;
      }
      return true;
    }
  }

  static bool _isYellowCornersPermuted(PieceView view, bool isWhiteOnU) {
    if (isWhiteOnU) {
      for (int i = 4; i < 8; i++) {
        if (view.corners[i].position != i) return false;
      }
      return true;
    } else {
      for (int i = 0; i < 4; i++) {
        if (view.corners[i].position != i) return false;
      }
      return true;
    }
  }

  static bool _isFullySolved(Facelets facelets) {
    for (int i = 0; i < 54; i++) {
      if (facelets[i] != FaceletConstants.solved[i]) return false;
    }
    return true;
  }
}
