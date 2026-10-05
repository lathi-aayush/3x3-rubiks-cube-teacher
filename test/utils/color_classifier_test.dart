import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:rubiks_cube_teacher/domain/detection/color_classifier.dart';
import 'package:rubiks_cube_teacher/domain/models/cube_color.dart';
import 'package:rubiks_cube_teacher/utils/lab_color.dart';
import 'package:rubiks_cube_teacher/utils/patch_sampler.dart';

void main() {
  group('Color Detection & Classifier Tests', () {
    test('CIELAB conversion and distance calculation', () {
      final white = LabColor.fromRGB(255, 255, 255);
      final black = LabColor.fromRGB(0, 0, 0);
      final red = LabColor.fromRGB(255, 0, 0);

      expect(white.distanceTo(white), 0.0);
      expect(white.distanceTo(black), greaterThan(90.0));
      expect(white.distanceTo(red), greaterThan(50.0));
    });

    test('ColorClassifier correctly classifies pure RGB baseline colors', () {
      final classifier = ColorClassifier.defaultReference();

      // Test classification of colors with minor noise
      final testCases = <(int, int, int), CubeColor>{
        (250, 250, 250): CubeColor.white,
        (230, 50, 50): CubeColor.red,
        (40, 190, 80): CubeColor.green,
        (245, 220, 60): CubeColor.yellow,
        (240, 110, 20): CubeColor.orange,
        (50, 120, 240): CubeColor.blue,
      };

      for (final entry in testCases.entries) {
        final (r, g, b) = entry.key;
        final lab = LabColor.fromRGB(r, g, b);
        expect(classifier.classify(lab), entry.value,
            reason: 'RGB ($r, $g, $b) was misclassified');
      }
    });

    test('PatchSampler samples 9 distinct patches from a generated 3x3 grid', () {
      // Create a 300x300 image with 9 solid color cells
      final testImage = img.Image(width: 300, height: 300);

      // Colors for 9 cells: 0..8
      final cellColors = [
        [255, 255, 255], // 0: White
        [255, 0, 0],     // 1: Red
        [0, 255, 0],     // 2: Green
        [255, 255, 0],   // 3: Yellow
        [255, 128, 0],   // 4: Orange
        [0, 0, 255],     // 5: Blue
        [255, 255, 255], // 6: White
        [255, 0, 0],     // 7: Red
        [0, 255, 0],     // 8: Green
      ];

      for (int row = 0; row < 3; row++) {
        for (int col = 0; col < 3; col++) {
          final color = cellColors[row * 3 + col];
          for (int y = row * 100; y < (row + 1) * 100; y++) {
            for (int x = col * 100; x < (col + 1) * 100; x++) {
              testImage.setPixelRgb(x, y, color[0], color[1], color[2]);
            }
          }
        }
      }

      final sampled = PatchSampler.sampleFaceletColors(testImage, patchRatio: 0.20);
      expect(sampled.length, 9);

      // Verify each sampled color matches the cell color
      final classifier = ColorClassifier.defaultReference();
      expect(classifier.classify(sampled[0]), CubeColor.white);
      expect(classifier.classify(sampled[1]), CubeColor.red);
      expect(classifier.classify(sampled[2]), CubeColor.green);
      expect(classifier.classify(sampled[3]), CubeColor.yellow);
      expect(classifier.classify(sampled[4]), CubeColor.orange);
      expect(classifier.classify(sampled[5]), CubeColor.blue);
      expect(classifier.classify(sampled[6]), CubeColor.white);
      expect(classifier.classify(sampled[7]), CubeColor.red);
      expect(classifier.classify(sampled[8]), CubeColor.green);
    });
  });
}
