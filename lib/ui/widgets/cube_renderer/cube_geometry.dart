import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../domain/models/move.dart';

/// 3D Vector for cube geometry calculations.
class Vec3 {
  final double x, y, z;

  const Vec3(this.x, this.y, this.z);

  Vec3 operator +(Vec3 o) => Vec3(x + o.x, y + o.y, z + o.z);
  Vec3 operator -(Vec3 o) => Vec3(x - o.x, y - o.y, z - o.z);
  Vec3 operator *(double s) => Vec3(x * s, y * s, z * s);

  double dot(Vec3 o) => x * o.x + y * o.y + z * o.z;

  Vec3 cross(Vec3 o) => Vec3(
        y * o.z - z * o.y,
        z * o.x - x * o.z,
        x * o.y - y * o.x,
      );

  double get length => math.sqrt(x * x + y * y + z * z);

  Vec3 normalized() {
    final l = length;
    if (l < 1e-9) return const Vec3(0, 0, 0);
    return Vec3(x / l, y / l, z / l);
  }

  /// Rotates around the X axis by [rad] radians.
  Vec3 rotateX(double rad) {
    final c = math.cos(rad);
    final s = math.sin(rad);
    return Vec3(x, y * c - z * s, y * s + z * c);
  }

  /// Rotates around the Y axis by [rad] radians.
  Vec3 rotateY(double rad) {
    final c = math.cos(rad);
    final s = math.sin(rad);
    return Vec3(x * c - z * s, y, x * s + z * c);
  }

  /// Rotates around the Z axis by [rad] radians.
  Vec3 rotateZ(double rad) {
    final c = math.cos(rad);
    final s = math.sin(rad);
    return Vec3(x * c - y * s, x * s + y * c, z);
  }
}

/// A polygon face on a cubie (quad).
class CubieQuad {
  final int cx, cy, cz; // Cubie grid position (-1, 0, 1)
  final int nx, ny, nz; // Normal direction (-1, 0, 1)
  final int stickerIndex; // 0..53 if external sticker, -1 if internal plastic
  final List<Vec3> localVertices; // 4 corners in cubie space

  const CubieQuad({
    required this.cx,
    required this.cy,
    required this.cz,
    required this.nx,
    required this.ny,
    required this.nz,
    required this.stickerIndex,
    required this.localVertices,
  });
}

/// Projected polygon ready for Painter's algorithm depth sorting and drawing.
class ProjectedQuad {
  final List<Offset> points;
  final double depth; // Average Z in camera space
  final double shade; // Lighting factor (0.6 to 1.1)
  final int stickerIndex; // 0..53 if external, -1 if plastic
  final int cx, cy, cz;

  const ProjectedQuad({
    required this.points,
    required this.depth,
    required this.shade,
    required this.stickerIndex,
    required this.cx,
    required this.cy,
    required this.cz,
  });
}

class CubeGeometry {
  static const double cubieSpacing = 1.0;
  static const double cubieSize = 0.93; // Small gap between cubies
  static const double halfSize = cubieSize / 2.0;

  static final List<CubieQuad> allQuads = _buildCubeQuads();

  static List<CubieQuad> _buildCubeQuads() {
    final quads = <CubieQuad>[];

    for (int cx = -1; cx <= 1; cx++) {
      for (int cy = -1; cy <= 1; cy++) {
        for (int cz = -1; cz <= 1; cz++) {
          // If strictly inside the cube (0, 0, 0), skip (invisible core)
          if (cx == 0 && cy == 0 && cz == 0) continue;

          final center = Vec3(
            cx * cubieSpacing,
            cy * cubieSpacing,
            cz * cubieSpacing,
          );

          // 6 Faces of each cubie
          final faces = [
            // +X (Right)
            _buildFace(cx, cy, cz, center, 1, 0, 0, [
              Vec3(halfSize, -halfSize, -halfSize),
              Vec3(halfSize, halfSize, -halfSize),
              Vec3(halfSize, halfSize, halfSize),
              Vec3(halfSize, -halfSize, halfSize),
            ]),
            // -X (Left)
            _buildFace(cx, cy, cz, center, -1, 0, 0, [
              Vec3(-halfSize, -halfSize, halfSize),
              Vec3(-halfSize, halfSize, halfSize),
              Vec3(-halfSize, halfSize, -halfSize),
              Vec3(-halfSize, -halfSize, -halfSize),
            ]),
            // +Y (Up)
            _buildFace(cx, cy, cz, center, 0, 1, 0, [
              Vec3(-halfSize, halfSize, halfSize),
              Vec3(halfSize, halfSize, halfSize),
              Vec3(halfSize, halfSize, -halfSize),
              Vec3(-halfSize, halfSize, -halfSize),
            ]),
            // -Y (Down)
            _buildFace(cx, cy, cz, center, 0, -1, 0, [
              Vec3(-halfSize, -halfSize, -halfSize),
              Vec3(halfSize, -halfSize, -halfSize),
              Vec3(halfSize, -halfSize, halfSize),
              Vec3(-halfSize, -halfSize, halfSize),
            ]),
            // +Z (Front)
            _buildFace(cx, cy, cz, center, 0, 0, 1, [
              Vec3(-halfSize, -halfSize, halfSize),
              Vec3(halfSize, -halfSize, halfSize),
              Vec3(halfSize, halfSize, halfSize),
              Vec3(-halfSize, halfSize, halfSize),
            ]),
            // -Z (Back)
            _buildFace(cx, cy, cz, center, 0, 0, -1, [
              Vec3(halfSize, -halfSize, -halfSize),
              Vec3(-halfSize, -halfSize, -halfSize),
              Vec3(-halfSize, halfSize, -halfSize),
              Vec3(halfSize, halfSize, -halfSize),
            ]),
          ];

          quads.addAll(faces);
        }
      }
    }

    return List.unmodifiable(quads);
  }

  static CubieQuad _buildFace(
    int cx,
    int cy,
    int cz,
    Vec3 center,
    int nx,
    int ny,
    int nz,
    List<Vec3> offsets,
  ) {
    final verts = offsets.map((o) => center + o).toList();
    int stickerIdx = -1;

    // Check if this face is on the exterior of the cube
    final isExterior = (nx == 1 && cx == 1) ||
        (nx == -1 && cx == -1) ||
        (ny == 1 && cy == 1) ||
        (ny == -1 && cy == -1) ||
        (nz == 1 && cz == 1) ||
        (nz == -1 && cz == -1);

    if (isExterior) {
      stickerIdx = MoveTables.findStickerOrNull(cx, cy, cz, nx, ny, nz);
    }

    return CubieQuad(
      cx: cx,
      cy: cy,
      cz: cz,
      nx: nx,
      ny: ny,
      nz: nz,
      stickerIndex: stickerIdx,
      localVertices: verts,
    );
  }

  /// Determines if cubie (cx, cy, cz) is in the rotating layer for [move].
  static bool isInLayer(Move move, int cx, int cy, int cz) {
    switch (move) {
      case Move.U:
      case Move.Ui:
      case Move.U2:
        return cy == 1;
      case Move.D:
      case Move.Di:
      case Move.D2:
        return cy == -1;
      case Move.R:
      case Move.Ri:
      case Move.R2:
        return cx == 1;
      case Move.L:
      case Move.Li:
      case Move.L2:
        return cx == -1;
      case Move.F:
      case Move.Fi:
      case Move.F2:
        return cz == 1;
      case Move.B:
      case Move.Bi:
      case Move.B2:
        return cz == -1;
    }
  }

  /// Rotates a 3D vertex according to the move's axis and angle.
  static Vec3 rotateForMove(Move move, Vec3 v, double angle) {
    switch (move) {
      case Move.U:
      case Move.Ui:
      case Move.U2:
        return v.rotateY(angle);
      case Move.D:
      case Move.Di:
      case Move.D2:
        return v.rotateY(-angle);
      case Move.R:
      case Move.Ri:
      case Move.R2:
        return v.rotateX(angle);
      case Move.L:
      case Move.Li:
      case Move.L2:
        return v.rotateX(-angle);
      case Move.F:
      case Move.Fi:
      case Move.F2:
        return v.rotateZ(angle);
      case Move.B:
      case Move.Bi:
      case Move.B2:
        return v.rotateZ(-angle);
    }
  }

  /// Target rotation angle in radians for a given move.
  static double targetAngleForMove(Move move) {
    switch (move) {
      case Move.U:
      case Move.D:
      case Move.R:
      case Move.L:
      case Move.F:
      case Move.B:
        return -math.pi / 2; // 90° clockwise
      case Move.Ui:
      case Move.Di:
      case Move.Ri:
      case Move.Li:
      case Move.Fi:
      case Move.Bi:
        return math.pi / 2; // 90° counter-clockwise
      case Move.U2:
      case Move.D2:
      case Move.R2:
      case Move.L2:
      case Move.F2:
      case Move.B2:
        return -math.pi; // 180°
    }
  }

  /// Projects 3D geometry into sorted 2D quads with lighting and depth sorting.
  static List<ProjectedQuad> project({
    required Size size,
    required double pitch, // View rotation around X axis
    required double yaw, // View rotation around Y axis
    Move? activeMove,
    double moveProgress = 0.0, // 0.0 to 1.0
  }) {
    final light = const Vec3(0.4, 0.9, -0.7).normalized();
    final double moveAngle = activeMove != null
        ? targetAngleForMove(activeMove) * moveProgress
        : 0.0;

    final center = Offset(size.width / 2, size.height / 2);
    final scale = math.min(size.width, size.height) * 0.17;
    const cameraDist = 8.5;

    final projected = <ProjectedQuad>[];

    for (final quad in allQuads) {
      final inLayer = activeMove != null &&
          isInLayer(activeMove, quad.cx, quad.cy, quad.cz);

      // 1. Layer rotation (if animated)
      Vec3 transform(Vec3 v) {
        var p = v;
        if (inLayer) {
          p = rotateForMove(activeMove, p, moveAngle);
        }
        // 2. View orbit rotation (yaw then pitch)
        p = p.rotateY(yaw);
        p = p.rotateX(pitch);
        return p;
      }

      final v0 = transform(quad.localVertices[0]);
      final v1 = transform(quad.localVertices[1]);
      final v2 = transform(quad.localVertices[2]);
      final v3 = transform(quad.localVertices[3]);

      // Calculate camera-space normal via cross product
      final edge1 = v1 - v0;
      final edge2 = v2 - v0;
      final normal = edge1.cross(edge2).normalized();

      // Backface culling: discard faces pointing away from the camera
      if (normal.z <= 0.01) continue;

      // Perspective projection
      Offset projectVertex(Vec3 v) {
        final factor = cameraDist / (v.z + cameraDist);
        return Offset(
          center.dx + v.x * factor * scale,
          center.dy - v.y * factor * scale,
        );
      }

      final p0 = projectVertex(v0);
      final p1 = projectVertex(v1);
      final p2 = projectVertex(v2);
      final p3 = projectVertex(v3);

      final avgDepth = (v0.z + v1.z + v2.z + v3.z) / 4.0;
      final dot = normal.dot(light);
      final shade = (0.75 + 0.35 * dot).clamp(0.6, 1.15);

      projected.add(ProjectedQuad(
        points: [p0, p1, p2, p3],
        depth: avgDepth,
        shade: shade,
        stickerIndex: quad.stickerIndex,
        cx: quad.cx,
        cy: quad.cy,
        cz: quad.cz,
      ));
    }

    // Depth sort: render furthest (largest depth) to closest (smallest depth)
    projected.sort((a, b) => b.depth.compareTo(a.depth));

    return projected;
  }
}
