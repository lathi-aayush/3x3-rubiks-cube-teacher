import '../../utils/lab_color.dart';
import '../models/cube_color.dart';

class ColorClassifier {
  final List<LabColor> _centers;
  // Face center colors in standard order: U, R, F, D, L, B
  static const List<CubeColor> _faceColors = [
    CubeColor.white,  // U (0)
    CubeColor.red,    // R (1)
    CubeColor.green,  // F (2)
    CubeColor.yellow, // D (3)
    CubeColor.orange, // L (4)
    CubeColor.blue,   // B (5)
  ];

  /// Builds a classifier calibrated from the 6 center stickers.
  /// [centers] must contain 6 LabColor instances in order: U, R, F, D, L, B.
  ColorClassifier.fromCenters(List<LabColor> centers)
      : assert(centers.length == 6, 'Must provide exactly 6 center colors'),
        _centers = List.unmodifiable(centers);

  /// Default baseline reference classifier using standard color definitions.
  factory ColorClassifier.defaultReference() {
    final ref = [
      LabColor.fromRGB(255, 255, 255), // White (U)
      LabColor.fromRGB(239, 68, 68),   // Red (R)
      LabColor.fromRGB(34, 197, 94),   // Green (F)
      LabColor.fromRGB(253, 224, 71),  // Yellow (D)
      LabColor.fromRGB(249, 115, 22),  // Orange (L)
      LabColor.fromRGB(59, 130, 246),  // Blue (B)
    ];
    return ColorClassifier.fromCenters(ref);
  }

  /// Classifies a sample LabColor to the nearest of the 6 calibrated colors.
  CubeColor classify(LabColor sample) {
    int bestIndex = 0;
    double minDistance = double.infinity;

    for (int i = 0; i < 6; i++) {
      final dist = sample.distanceTo(_centers[i]);
      if (dist < minDistance) {
        minDistance = dist;
        bestIndex = i;
      }
    }

    return _faceColors[bestIndex];
  }

  /// Classifies a sample LabColor and returns its color integer (0..5).
  int classifyInt(LabColor sample) => classify(sample).index;
}
