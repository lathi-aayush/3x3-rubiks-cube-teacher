import 'package:image/image.dart' as img;
import 'lab_color.dart';

class PatchSampler {
  /// Samples 9 center patches from a 3x3 grid within [image].
  /// [patchRatio] is the fraction of cell width/height to sample around the center (default 0.20 = center 20%).
  /// Returns a list of 9 [LabColor] instances in row-major order:
  /// [0: top-left, 1: top-center, 2: top-right,
  ///  3: mid-left, 4: center,     5: mid-right,
  ///  6: bot-left, 7: bot-center, 8: bot-right]
  static List<LabColor> sampleFaceletColors(
    img.Image image, {
    double patchRatio = 0.20,
  }) {
    final colors = <LabColor>[];
    final cellWidth = image.width / 3.0;
    final cellHeight = image.height / 3.0;

    for (int row = 0; row < 3; row++) {
      for (int col = 0; col < 3; col++) {
        final cellCenterX = (col + 0.5) * cellWidth;
        final cellCenterY = (row + 0.5) * cellHeight;

        final halfPatchW = (cellWidth * patchRatio) / 2.0;
        final halfPatchH = (cellHeight * patchRatio) / 2.0;

        final startX = (cellCenterX - halfPatchW).clamp(0.0, image.width - 1.0).toInt();
        final endX = (cellCenterX + halfPatchW).clamp(0.0, image.width - 1.0).toInt();
        final startY = (cellCenterY - halfPatchH).clamp(0.0, image.height - 1.0).toInt();
        final endY = (cellCenterY + halfPatchH).clamp(0.0, image.height - 1.0).toInt();

        double sumR = 0;
        double sumG = 0;
        double sumB = 0;
        int count = 0;

        for (int y = startY; y <= endY; y++) {
          for (int x = startX; x <= endX; x++) {
            final pixel = image.getPixel(x, y);
            sumR += pixel.r;
            sumG += pixel.g;
            sumB += pixel.b;
            count++;
          }
        }

        if (count == 0) {
          final pixel = image.getPixel(cellCenterX.toInt(), cellCenterY.toInt());
          colors.add(LabColor.fromRGB(pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt()));
        } else {
          colors.add(LabColor.fromRGB(
            (sumR / count).round(),
            (sumG / count).round(),
            (sumB / count).round(),
          ));
        }
      }
    }

    return colors;
  }
}
