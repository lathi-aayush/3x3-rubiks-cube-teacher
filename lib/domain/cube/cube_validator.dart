import 'facelets.dart';
import 'piece_view.dart';

enum ValidationKind {
  wrongColorCount, // a color appears != 9 times
  twistedCorner,   // corner orientation sum != 0 mod 3
  flippedEdge,     // edge orientation sum != 0 mod 2
  parityError,     // corner perm parity != edge perm parity
}

class ValidationError {
  final String message;
  final ValidationKind kind;

  const ValidationError({
    required this.message,
    required this.kind,
  });

  @override
  String toString() => 'ValidationError($kind): $message';
}

class CubeValidator {
  /// Validates the 54-facelet array against physical Rubik's cube laws.
  /// Returns null if valid, or a [ValidationError] describing the first violation found.
  static ValidationError? validate(Facelets facelets) {
    if (facelets.length != 54) {
      return const ValidationError(
        message: 'Cube state must contain exactly 54 facelets.',
        kind: ValidationKind.wrongColorCount,
      );
    }

    // 1. Color Count Check (exactly 9 of each color 0..5)
    final counts = List<int>.filled(6, 0);
    for (final color in facelets) {
      if (color < 0 || color > 5) {
        return ValidationError(
          message: 'Unknown color index $color detected.',
          kind: ValidationKind.wrongColorCount,
        );
      }
      counts[color]++;
    }

    for (int c = 0; c < 6; c++) {
      if (counts[c] != 9) {
        return ValidationError(
          message: 'Each color must appear exactly 9 times. Color $c has ${counts[c]}.',
          kind: ValidationKind.wrongColorCount,
        );
      }
    }

    // Derive piece view
    final view = PieceView.from(facelets);

    // Verify all 8 corners are valid unique pieces
    final cornerPositions = view.corners.map((c) => c.position).toList();
    if (cornerPositions.any((pos) => pos < 0 || pos > 7) ||
        cornerPositions.toSet().length != 8) {
      return const ValidationError(
        message: 'Corner pieces are misplaced or duplicated.',
        kind: ValidationKind.twistedCorner,
      );
    }

    // Verify all 12 edges are valid unique pieces
    final edgePositions = view.edges.map((e) => e.position).toList();
    if (edgePositions.any((pos) => pos < 0 || pos > 11) ||
        edgePositions.toSet().length != 12) {
      return const ValidationError(
        message: 'Edge pieces are misplaced or duplicated.',
        kind: ValidationKind.flippedEdge,
      );
    }

    // 2. Corner Orientation Sum (must be 0 mod 3)
    final cornerOriSum = view.corners.fold<int>(0, (sum, c) => sum + c.orientation);
    if (cornerOriSum % 3 != 0) {
      return const ValidationError(
        message: 'A corner appears to be physically twisted.',
        kind: ValidationKind.twistedCorner,
      );
    }

    // 3. Edge Orientation Sum (must be 0 mod 2)
    final edgeOriSum = view.edges.fold<int>(0, (sum, e) => sum + e.orientation);
    if (edgeOriSum % 2 != 0) {
      return const ValidationError(
        message: 'An edge appears to be physically flipped.',
        kind: ValidationKind.flippedEdge,
      );
    }

    // 4. Permutation Parity Check
    final cornerParity = _permutationParity(cornerPositions);
    final edgeParity = _permutationParity(edgePositions);
    if (cornerParity != edgeParity) {
      return const ValidationError(
        message: 'Cube has parity error (two pieces swapped).',
        kind: ValidationKind.parityError,
      );
    }

    return null;
  }

  /// Computes permutation parity: 0 for even, 1 for odd.
  /// Uses cycle decomposition: parity = (length - cycleCount) % 2.
  static int _permutationParity(List<int> perm) {
    final visited = List<bool>.filled(perm.length, false);
    int cycles = 0;

    for (int i = 0; i < perm.length; i++) {
      if (!visited[i]) {
        cycles++;
        int current = i;
        while (!visited[current]) {
          visited[current] = true;
          current = perm[current];
        }
      }
    }

    return (perm.length - cycles) % 2;
  }
}
