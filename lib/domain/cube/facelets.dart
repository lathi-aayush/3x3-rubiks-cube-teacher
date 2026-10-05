typedef Facelets = List<int>;

class FaceletConstants {
  /// Solved state constant of 54 integers:
  /// U (0-8): White (0)
  /// R (9-17): Red (4)
  /// F (18-26): Green (2)
  /// D (27-35): Yellow (1)
  /// L (36-44): Orange (5)
  /// B (45-53): Blue (3)
  static const Facelets solved = [
    0, 0, 0, 0, 0, 0, 0, 0, 0, // U (White)
    4, 4, 4, 4, 4, 4, 4, 4, 4, // R (Red)
    2, 2, 2, 2, 2, 2, 2, 2, 2, // F (Green)
    1, 1, 1, 1, 1, 1, 1, 1, 1, // D (Yellow)
    5, 5, 5, 5, 5, 5, 5, 5, 5, // L (Orange)
    3, 3, 3, 3, 3, 3, 3, 3, 3, // B (Blue)
  ];

  static Facelets createSolved() => List<int>.from(solved);

  static Facelets copy(Facelets facelets) => List<int>.from(facelets);

  static int centerColor(Facelets facelets, int faceIndex) {
    assert(faceIndex >= 0 && faceIndex < 6);
    return facelets[faceIndex * 9 + 4];
  }
}
