enum Stage {
  whiteCross,       // stage 1
  whiteCorners,     // stage 2
  middleEdges,      // stage 3
  yellowCross,      // stage 4
  orientCorners,    // stage 5
  permuteCorners,   // stage 6
  permuteEdges,     // stage 7
}

extension StageExtension on Stage {
  int get order => index + 1;

  String get displayName {
    switch (this) {
      case Stage.whiteCross:
        return 'White Cross';
      case Stage.whiteCorners:
        return 'White Corners';
      case Stage.middleEdges:
        return 'Middle Edges';
      case Stage.yellowCross:
        return 'Yellow Cross';
      case Stage.orientCorners:
        return 'Orient Yellow Corners';
      case Stage.permuteCorners:
        return 'Permute Yellow Corners';
      case Stage.permuteEdges:
        return 'Permute Yellow Edges';
    }
  }

  String get description {
    switch (this) {
      case Stage.whiteCross:
        return 'Form a white cross matching adjacent center colors.';
      case Stage.whiteCorners:
        return 'Solve all 4 white corners to complete the first layer.';
      case Stage.middleEdges:
        return 'Place the 4 middle-layer edges.';
      case Stage.yellowCross:
        return 'Form a yellow cross on the opposite face.';
      case Stage.orientCorners:
        return 'Orient all yellow corners so the yellow face is complete.';
      case Stage.permuteCorners:
        return 'Move yellow corners to their correct positions.';
      case Stage.permuteEdges:
        return 'Cycle remaining edges to fully solve the cube.';
    }
  }
}
