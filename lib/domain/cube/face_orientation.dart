/// Directional orientation map describing the 4 adjacent faces
/// for each of the 6 faces in the 54-facelet coordinate system.
class FaceOrientation {
  final int faceIndex;
  final String faceName;
  final int centerColor;
  final int topFace;
  final int bottomFace;
  final int leftFace;
  final int rightFace;
  final String orientationHint;

  const FaceOrientation({
    required this.faceIndex,
    required this.faceName,
    required this.centerColor,
    required this.topFace,
    required this.bottomFace,
    required this.leftFace,
    required this.rightFace,
    required this.orientationHint,
  });

  /// The 6 canonical faces in order: U (0), R (1), F (2), D (3), L (4), B (5).
  static const List<FaceOrientation> orientations = [
    // 0: Up (White) - row 0 touches Front, row 2 touches Back, col 0 touches Left, col 2 touches Right
    FaceOrientation(
      faceIndex: 0,
      faceName: 'Up (White)',
      centerColor: 0,
      topFace: 2,       // Front (Green)
      bottomFace: 5,    // Back (Blue)
      leftFace: 4,      // Left (Orange)
      rightFace: 1,     // Right (Red)
      orientationHint: 'Front (Green) at top • Back (Blue) at bottom',
    ),
    // 1: Right (Red) - top touches Up, bottom touches Down, left touches Front, right touches Back
    FaceOrientation(
      faceIndex: 1,
      faceName: 'Right (Red)',
      centerColor: 4,
      topFace: 0,       // Up (White)
      bottomFace: 3,    // Down (Yellow)
      leftFace: 2,      // Front (Green)
      rightFace: 5,     // Back (Blue)
      orientationHint: 'Up (White) at top • Front (Green) at left',
    ),
    // 2: Front (Green) - top touches Up, bottom touches Down, left touches Left, right touches Right
    FaceOrientation(
      faceIndex: 2,
      faceName: 'Front (Green)',
      centerColor: 2,
      topFace: 0,       // Up (White)
      bottomFace: 3,    // Down (Yellow)
      leftFace: 4,      // Left (Orange)
      rightFace: 1,     // Right (Red)
      orientationHint: 'Up (White) at top • Left (Orange) at left',
    ),
    // 3: Down (Yellow) - row 0 touches Front, row 2 touches Back, col 0 touches Left, col 2 touches Right
    FaceOrientation(
      faceIndex: 3,
      faceName: 'Down (Yellow)',
      centerColor: 1,
      topFace: 2,       // Front (Green)
      bottomFace: 5,    // Back (Blue)
      leftFace: 4,      // Left (Orange)
      rightFace: 1,     // Right (Red)
      orientationHint: 'Front (Green) at top • Back (Blue) at bottom',
    ),
    // 4: Left (Orange) - top touches Up, bottom touches Down, left touches Back, right touches Front
    FaceOrientation(
      faceIndex: 4,
      faceName: 'Left (Orange)',
      centerColor: 5,
      topFace: 0,       // Up (White)
      bottomFace: 3,    // Down (Yellow)
      leftFace: 5,      // Back (Blue)
      rightFace: 2,     // Front (Green)
      orientationHint: 'Up (White) at top • Front (Green) at right',
    ),
    // 5: Back (Blue) - top touches Up, bottom touches Down, left touches Right, right touches Left
    FaceOrientation(
      faceIndex: 5,
      faceName: 'Back (Blue)',
      centerColor: 3,
      topFace: 0,       // Up (White)
      bottomFace: 3,    // Down (Yellow)
      leftFace: 1,      // Right (Red)
      rightFace: 4,     // Left (Orange)
      orientationHint: 'Up (White) at top • Right (Red) at left',
    ),
  ];

  static FaceOrientation forFace(int faceIndex) {
    assert(faceIndex >= 0 && faceIndex < 6);
    return orientations[faceIndex];
  }
}
