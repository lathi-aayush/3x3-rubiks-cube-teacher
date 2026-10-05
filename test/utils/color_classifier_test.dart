import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:rubiks_cube_teacher/domain/detection/color_classifier.dart';
import 'package:rubiks_cube_teacher/domain/models/cube_color.dart';
import 'package:rubiks_cube_teacher/domain/cube/facelets.dart';
import 'package:rubiks_cube_teacher/providers/scan_provider.dart';
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

    test('PatchSampler with boxRatio on portrait image samples centered box', () {
      final portrait = img.Image(width: 1080, height: 1920);
      // Fill entire background with black
      for (int y = 0; y < 1920; y++) {
        for (int x = 0; x < 1080; x++) {
          portrait.setPixelRgb(x, y, 0, 0, 0);
        }
      }
      // Fill centered box with white
      const boxSize = 1080 * 0.78;
      final boxLeft = ((1080 - boxSize) / 2).toInt();
      final boxTop = ((1920 - boxSize) / 2).toInt();
      for (int y = boxTop; y < boxTop + boxSize.toInt(); y++) {
        for (int x = boxLeft; x < boxLeft + boxSize.toInt(); x++) {
          portrait.setPixelRgb(x, y, 255, 255, 255);
        }
      }

      final sampled = PatchSampler.sampleFaceletColors(portrait, boxRatio: 0.78);
      final classifier = ColorClassifier.defaultReference();
      for (int i = 0; i < 9; i++) {
        expect(classifier.classify(sampled[i]), CubeColor.white,
            reason: 'Sticker $i inside centered box should be white');
      }
    });

    test('ScanProvider calibrates 6 centers and correctly recognizes solved cube', () {
      final scanProv = ScanProvider();

      // Simulated real-world lighting colors for the 6 faces (U, R, F, D, L, B)
      // Notice slight lighting variations (indoor warm LED):
      final faceBaseColors = [
        LabColor.fromRGB(240, 240, 235), // White with slight warm tint
        LabColor.fromRGB(215, 45, 40),   // Red
        LabColor.fromRGB(30, 185, 75),   // Green
        LabColor.fromRGB(245, 215, 55),  // Yellow
        LabColor.fromRGB(235, 110, 25),  // Orange
        LabColor.fromRGB(45, 115, 235),  // Blue
      ];

      for (int f = 0; f < 6; f++) {
        final base = faceBaseColors[f];
        // 9 stickers on face f with small sensor noise:
        final sampled9 = List.generate(9, (i) {
          return LabColor(base.l + (i % 2 == 0 ? 0.5 : -0.5), base.a, base.b);
        });
        scanProv.captureCurrentFace(sampled9);
      }

      expect(scanProv.isScanComplete, isTrue);
      expect(scanProv.validate(), isTrue);
      expect(scanProv.validationError, isNull);

      // Verify the 54 facelets match FaceletConstants.solved!
      for (int i = 0; i < 54; i++) {
        expect(scanProv.facelets[i], FaceletConstants.solved[i],
            reason: 'Facelet $i should match solved state');
      }
    });
  });
}
