enum Move {
  U,
  Ui,
  U2,
  D,
  Di,
  D2,
  R,
  Ri,
  R2,
  L,
  Li,
  L2,
  F,
  Fi,
  F2,
  B,
  Bi,
  B2,
}

extension MoveExtension on Move {
  String get notation {
    switch (this) {
      case Move.U:
        return 'U';
      case Move.Ui:
        return "U'";
      case Move.U2:
        return 'U2';
      case Move.D:
        return 'D';
      case Move.Di:
        return "D'";
      case Move.D2:
        return 'D2';
      case Move.R:
        return 'R';
      case Move.Ri:
        return "R'";
      case Move.R2:
        return 'R2';
      case Move.L:
        return 'L';
      case Move.Li:
        return "L'";
      case Move.L2:
        return 'L2';
      case Move.F:
        return 'F';
      case Move.Fi:
        return "F'";
      case Move.F2:
        return 'F2';
      case Move.B:
        return 'B';
      case Move.Bi:
        return "B'";
      case Move.B2:
        return 'B2';
    }
  }

  Move get inverse {
    switch (this) {
      case Move.U:
        return Move.Ui;
      case Move.Ui:
        return Move.U;
      case Move.U2:
        return Move.U2;
      case Move.D:
        return Move.Di;
      case Move.Di:
        return Move.D;
      case Move.D2:
        return Move.D2;
      case Move.R:
        return Move.Ri;
      case Move.Ri:
        return Move.R;
      case Move.R2:
        return Move.R2;
      case Move.L:
        return Move.Li;
      case Move.Li:
        return Move.L;
      case Move.L2:
        return Move.L2;
      case Move.F:
        return Move.Fi;
      case Move.Fi:
        return Move.F;
      case Move.F2:
        return Move.F2;
      case Move.B:
        return Move.Bi;
      case Move.Bi:
        return Move.B;
      case Move.B2:
        return Move.B2;
    }
  }

  List<int> get permutationTable => MoveTables.tableFor(this);
}

class _StickerCoord {
  final int x, y, z;
  final int nx, ny, nz;
  const _StickerCoord(this.x, this.y, this.z, this.nx, this.ny, this.nz);
}

class MoveTables {
  // 54 sticker coordinates in 3D: position (x, y, z) in {-1, 0, 1} and normal (nx, ny, nz)
  static final List<_StickerCoord> _coords = _buildCoords();

  static List<_StickerCoord> _buildCoords() {
    final list = <_StickerCoord>[];

    // Face U (0..8): y = 1, normal (0, 1, 0)
    // Layout: row 0: z=1 (x=-1, 0, 1); row 1: z=0 (x=-1, 0, 1); row 2: z=-1 (x=-1, 0, 1)
    for (final z in [1, 0, -1]) {
      for (final x in [-1, 0, 1]) {
        list.add(_StickerCoord(x, 1, z, 0, 1, 0));
      }
    }

    // Face R (9..17): x = 1, normal (1, 0, 0)
    // Left is Front (z=1), Right is Back (z=-1). Top is Up (y=1), Bottom is Down (y=-1)
    for (final y in [1, 0, -1]) {
      for (final z in [1, 0, -1]) {
        list.add(_StickerCoord(1, y, z, 1, 0, 0));
      }
    }

    // Face F (18..26): z = 1, normal (0, 0, 1)
    // Left is Orange (x=-1), Right is Red (x=1). Top is Up (y=1), Bottom is Down (y=-1)
    for (final y in [1, 0, -1]) {
      for (final x in [-1, 0, 1]) {
        list.add(_StickerCoord(x, y, 1, 0, 0, 1));
      }
    }

    // Face D (27..35): y = -1, normal (0, -1, 0)
    // Viewed from below: Front is z=1 (top of grid), Back is z=-1 (bottom)
    for (final z in [1, 0, -1]) {
      for (final x in [-1, 0, 1]) {
        list.add(_StickerCoord(x, -1, z, 0, -1, 0));
      }
    }

    // Face L (36..44): x = -1, normal (-1, 0, 0)
    // Left is Back (z=-1), Right is Front (z=1). Top is Up (y=1), Bottom is Down (y=-1)
    for (final y in [1, 0, -1]) {
      for (final z in [-1, 0, 1]) {
        list.add(_StickerCoord(-1, y, z, -1, 0, 0));
      }
    }

    // Face B (45..53): z = -1, normal (0, 0, -1)
    // Left is Red (x=1), Right is Orange (x=-1). Top is Up (y=1), Bottom is Down (y=-1)
    for (final y in [1, 0, -1]) {
      for (final x in [1, 0, -1]) {
        list.add(_StickerCoord(x, y, -1, 0, 0, -1));
      }
    }

    assert(list.length == 54);
    return list;
  }

  static int _findSticker(int x, int y, int z, int nx, int ny, int nz) {
    for (int i = 0; i < 54; i++) {
      final c = _coords[i];
      if (c.x == x && c.y == y && c.z == z && c.nx == nx && c.ny == ny && c.nz == nz) {
        return i;
      }
    }
    throw StateError('Sticker not found at ($x, $y, $z) norm ($nx, $ny, nz)');
  }

  // 3D rotations for the 6 base moves:
  // U: y == 1, clockwise from +Y
  static void _targetRotateU(_StickerCoord t, List<int> o) {
    o[0] = -t.z;
    o[1] = t.y;
    o[2] = t.x;
    o[3] = -t.nz;
    o[4] = t.ny;
    o[5] = t.nx;
  }

  // D: y == -1, clockwise from -Y
  static void _targetRotateD(_StickerCoord t, List<int> o) {
    o[0] = t.z;
    o[1] = t.y;
    o[2] = -t.x;
    o[3] = t.nz;
    o[4] = t.ny;
    o[5] = -t.nx;
  }

  // R: x == 1, clockwise from +X
  static void _targetRotateR(_StickerCoord t, List<int> o) {
    o[0] = t.x;
    o[1] = t.z;
    o[2] = -t.y;
    o[3] = t.nx;
    o[4] = t.nz;
    o[5] = -t.ny;
  }

  // L: x == -1, clockwise from -X
  static void _targetRotateL(_StickerCoord t, List<int> o) {
    o[0] = t.x;
    o[1] = -t.z;
    o[2] = t.y;
    o[3] = t.nx;
    o[4] = -t.nz;
    o[5] = t.ny;
  }

  // F: z == 1, clockwise from +Z
  static void _targetRotateF(_StickerCoord t, List<int> o) {
    o[0] = t.y;
    o[1] = -t.x;
    o[2] = t.z;
    o[3] = t.ny;
    o[4] = -t.nx;
    o[5] = t.nz;
  }

  // B: z == -1, clockwise from -Z
  static void _targetRotateB(_StickerCoord t, List<int> o) {
    o[0] = -t.y;
    o[1] = t.x;
    o[2] = t.z;
    o[3] = -t.ny;
    o[4] = t.nx;
    o[5] = t.nz;
  }

  static List<int> _buildU() {
    final perm = List<int>.generate(54, (i) => i);
    final o = List<int>.filled(6, 0);
    for (int i = 0; i < 54; i++) {
      final t = _coords[i];
      if (t.y == 1) {
        _targetRotateU(t, o);
        final dest = _findSticker(o[0], o[1], o[2], o[3], o[4], o[5]);
        perm[dest] = i;
      }
    }
    return List<int>.unmodifiable(perm);
  }

  static List<int> _buildD() {
    final perm = List<int>.generate(54, (i) => i);
    final o = List<int>.filled(6, 0);
    for (int i = 0; i < 54; i++) {
      final t = _coords[i];
      if (t.y == -1) {
        _targetRotateD(t, o);
        final dest = _findSticker(o[0], o[1], o[2], o[3], o[4], o[5]);
        perm[dest] = i;
      }
    }
    return List<int>.unmodifiable(perm);
  }

  static List<int> _buildR() {
    final perm = List<int>.generate(54, (i) => i);
    final o = List<int>.filled(6, 0);
    for (int i = 0; i < 54; i++) {
      final t = _coords[i];
      if (t.x == 1) {
        _targetRotateR(t, o);
        final dest = _findSticker(o[0], o[1], o[2], o[3], o[4], o[5]);
        perm[dest] = i;
      }
    }
    return List<int>.unmodifiable(perm);
  }

  static List<int> _buildL() {
    final perm = List<int>.generate(54, (i) => i);
    final o = List<int>.filled(6, 0);
    for (int i = 0; i < 54; i++) {
      final t = _coords[i];
      if (t.x == -1) {
        _targetRotateL(t, o);
        final dest = _findSticker(o[0], o[1], o[2], o[3], o[4], o[5]);
        perm[dest] = i;
      }
    }
    return List<int>.unmodifiable(perm);
  }

  static List<int> _buildF() {
    final perm = List<int>.generate(54, (i) => i);
    final o = List<int>.filled(6, 0);
    for (int i = 0; i < 54; i++) {
      final t = _coords[i];
      if (t.z == 1) {
        _targetRotateF(t, o);
        final dest = _findSticker(o[0], o[1], o[2], o[3], o[4], o[5]);
        perm[dest] = i;
      }
    }
    return List<int>.unmodifiable(perm);
  }

  static List<int> _buildB() {
    final perm = List<int>.generate(54, (i) => i);
    final o = List<int>.filled(6, 0);
    for (int i = 0; i < 54; i++) {
      final t = _coords[i];
      if (t.z == -1) {
        _targetRotateB(t, o);
        final dest = _findSticker(o[0], o[1], o[2], o[3], o[4], o[5]);
        perm[dest] = i;
      }
    }
    return List<int>.unmodifiable(perm);
  }

  static final List<int> _u = _buildU();
  static final List<int> _d = _buildD();
  static final List<int> _f = _buildF();
  static final List<int> _b = _buildB();
  static final List<int> _r = _buildR();
  static final List<int> _l = _buildL();

  static final Map<Move, List<int>> _allTables = {
    Move.U: _u,
    Move.U2: _compose(_u, _u),
    Move.Ui: _compose(_u, _compose(_u, _u)),
    Move.D: _d,
    Move.D2: _compose(_d, _d),
    Move.Di: _compose(_d, _compose(_d, _d)),
    Move.F: _f,
    Move.F2: _compose(_f, _f),
    Move.Fi: _compose(_f, _compose(_f, _f)),
    Move.B: _b,
    Move.B2: _compose(_b, _b),
    Move.Bi: _compose(_b, _compose(_b, _b)),
    Move.R: _r,
    Move.R2: _compose(_r, _r),
    Move.Ri: _compose(_r, _compose(_r, _r)),
    Move.L: _l,
    Move.L2: _compose(_l, _l),
    Move.Li: _compose(_l, _compose(_l, _l)),
  };

  static List<int> tableFor(Move move) => _allTables[move]!;

  static List<int> _compose(List<int> a, List<int> b) {
    return List<int>.generate(54, (i) => a[b[i]], growable: false);
  }
}
