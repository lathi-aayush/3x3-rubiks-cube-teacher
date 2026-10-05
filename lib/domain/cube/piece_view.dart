import 'facelets.dart';

class CornerPiece {
  final int position;     // 0–7, solved position this corner piece belongs to
  final int orientation;  // 0=correct (U/D facing U/D), 1=clockwise twist, 2=anti-clockwise twist

  const CornerPiece({
    required this.position,
    required this.orientation,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CornerPiece &&
          runtimeType == other.runtimeType &&
          position == other.position &&
          orientation == other.orientation;

  @override
  int get hashCode => Object.hash(position, orientation);

  @override
  String toString() => 'CornerPiece(pos: $position, ori: $orientation)';
}

class EdgePiece {
  final int position;     // 0–11, solved position this edge piece belongs to
  final int orientation;  // 0=correct, 1=flipped

  const EdgePiece({
    required this.position,
    required this.orientation,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EdgePiece &&
          runtimeType == other.runtimeType &&
          position == other.position &&
          orientation == other.orientation;

  @override
  int get hashCode => Object.hash(position, orientation);

  @override
  String toString() => 'EdgePiece(pos: $position, ori: $orientation)';
}

class PieceView {
  final List<CornerPiece> corners; // length 8
  final List<EdgePiece> edges;     // length 12

  const PieceView({
    required this.corners,
    required this.edges,
  });

  // 8 Corner slot facelet indices ordered as: [U/D_face, clockwise_face, counterclockwise_face]
  // 0: URF -> U(0), R(9), F(20)
  // 1: ULF -> U(2), F(18), L(38)
  // 2: ULB -> U(8), L(36), B(47)
  // 3: URB -> U(6), B(45), R(11)
  // 4: DRF -> D(29), F(26), R(15)
  // 5: DLF -> D(27), L(44), F(24)
  // 6: DLB -> D(33), B(53), L(42)
  // 7: DRB -> D(35), R(17), B(51)
  static const List<List<int>> cornerIndices = [
    [0, 9, 20],   // 0: URF
    [2, 18, 38],  // 1: ULF
    [8, 36, 47],  // 2: ULB
    [6, 45, 11],  // 3: URB
    [29, 26, 15], // 4: DRF
    [27, 44, 24], // 5: DLF
    [33, 53, 42], // 6: DLB
    [35, 17, 51], // 7: DRB
  ];

  // 12 Edge slot facelet indices: [primary (U/D/F/B), secondary (R/L)]
  static const List<List<int>> edgeIndices = [
    [3, 10],  // 0: UR
    [1, 19],  // 1: UF
    [5, 37],  // 2: UL
    [7, 46],  // 3: UB
    [32, 16], // 4: DR
    [28, 25], // 5: DF
    [30, 43], // 6: DL
    [34, 52], // 7: DB
    [23, 12], // 8: FR
    [21, 41], // 9: FL
    [50, 39], // 10: BL
    [48, 14], // 11: BR
  ];

  // Target color sets for corners (White=0, Yellow=1, Green=2, Blue=3, Red=4, Orange=5)
  static final List<Set<int>> _cornerColorSets = cornerIndices.map((indices) {
    return indices.map((idx) => FaceletConstants.solved[idx]).toSet();
  }).toList();

  // Target color sets for edges
  static final List<Set<int>> _edgeColorSets = edgeIndices.map((indices) {
    return indices.map((idx) => FaceletConstants.solved[idx]).toSet();
  }).toList();

  /// Pure derivation from facelets array. O(1).
  static PieceView from(Facelets facelets) {
    assert(facelets.length == 54);

    final extractedCorners = <CornerPiece>[];
    for (int slot = 0; slot < 8; slot++) {
      final indices = cornerIndices[slot];
      final c0 = facelets[indices[0]];
      final c1 = facelets[indices[1]];
      final c2 = facelets[indices[2]];
      final colors = {c0, c1, c2};

      int piecePos = -1;
      for (int p = 0; p < 8; p++) {
        if (_setEquals(colors, _cornerColorSets[p])) {
          piecePos = p;
          break;
        }
      }

      int orientation = 0;
      if (c0 == 0 || c0 == 1) {
        orientation = 0;
      } else if (c1 == 0 || c1 == 1) {
        orientation = 1;
      } else if (c2 == 0 || c2 == 1) {
        orientation = 2;
      }

      extractedCorners.add(CornerPiece(
        position: piecePos,
        orientation: orientation,
      ));
    }

    final extractedEdges = <EdgePiece>[];
    for (int slot = 0; slot < 12; slot++) {
      final indices = edgeIndices[slot];
      final e0 = facelets[indices[0]];
      final e1 = facelets[indices[1]];
      final colors = {e0, e1};

      int piecePos = -1;
      for (int p = 0; p < 12; p++) {
        if (_setEquals(colors, _edgeColorSets[p])) {
          piecePos = p;
          break;
        }
      }

      int orientation = 0;
      if (piecePos >= 0 && piecePos < 8) {
        // U or D edge
        orientation = (e0 == 0 || e0 == 1) ? 0 : 1;
      } else if (piecePos >= 8) {
        // Middle layer edge
        orientation = (e0 == 2 || e0 == 3) ? 0 : 1;
      }

      extractedEdges.add(EdgePiece(
        position: piecePos,
        orientation: orientation,
      ));
    }

    return PieceView(
      corners: List.unmodifiable(extractedCorners),
      edges: List.unmodifiable(extractedEdges),
    );
  }

  static bool _setEquals(Set<int> a, Set<int> b) {
    if (a.length != b.length) return false;
    return a.containsAll(b);
  }
}
