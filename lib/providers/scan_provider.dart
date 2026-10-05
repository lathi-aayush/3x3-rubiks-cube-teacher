import 'package:flutter/foundation.dart';
import '../domain/cube/cube_validator.dart';
import '../domain/detection/color_classifier.dart';
import '../utils/lab_color.dart';

class ScanProvider extends ChangeNotifier {
  // 6 faces to scan in order: U, R, F, D, L, B
  static const List<String> faceNames = ['Up (White)', 'Right (Red)', 'Front (Green)', 'Down (Yellow)', 'Left (Orange)', 'Back (Blue)'];
  static const List<int> defaultCenters = [0, 4, 2, 1, 5, 3]; // U=0, R=4, F=2, D=1, L=5, B=3

  int _currentFaceIndex = 0;
  int get currentFaceIndex => _currentFaceIndex;
  String get currentFaceName => faceNames[_currentFaceIndex];

  // 54 facelet integers, initialized to -1 (unscanned)
  final List<int> _facelets = List<int>.filled(54, -1);
  List<int> get facelets => List.unmodifiable(_facelets);

  // 6 calibrated center LAB values: U, R, F, D, L, B
  final List<LabColor?> _centerLabs = List<LabColor?>.filled(6, null);

  // Raw sampled 9 patches per face: allows re-evaluating with calibrated classifier
  final List<List<LabColor>?> _rawFaceSamples = List<List<LabColor>?>.filled(6, null);

  ColorClassifier? _classifier;
  ValidationError? _validationError;
  ValidationError? get validationError => _validationError;

  bool get isScanComplete => _facelets.every((color) => color >= 0 && color <= 5);

  /// Captures the 9 facelets of the current face using the 9 sampled Lab colors.
  void captureCurrentFace(List<LabColor> sampled9) {
    assert(sampled9.length == 9);

    final faceIdx = _currentFaceIndex;
    _rawFaceSamples[faceIdx] = List<LabColor>.from(sampled9);
    // Center sticker is at index 4 of the 3x3 patch
    _centerLabs[faceIdx] = sampled9[4];

    // Reclassify all faces with the latest centers
    _reclassifyScannedFaces();

    // Move to next face if not at the end
    if (_currentFaceIndex < 5) {
      _currentFaceIndex++;
    }

    validate();
    notifyListeners();
  }

  void _reclassifyScannedFaces() {
    // If all 6 centers are calibrated, create trained classifier from the physical cube
    if (_centerLabs.every((c) => c != null)) {
      _classifier = ColorClassifier.fromCenters(_centerLabs.cast<LabColor>());
    } else {
      // Build hybrid reference: real center if already scanned, otherwise default reference
      final hybridCenters = <LabColor>[];
      final defaultCentersRef = ColorClassifier.defaultReferenceCenters();
      for (int i = 0; i < 6; i++) {
        hybridCenters.add(_centerLabs[i] ?? defaultCentersRef[i]);
      }
      _classifier = ColorClassifier.fromCenters(hybridCenters);
    }

    // Reclassify every face that has been scanned so far
    for (int f = 0; f < 6; f++) {
      final samples = _rawFaceSamples[f];
      if (samples == null) continue;
      final startIndex = f * 9;
      for (int i = 0; i < 9; i++) {
        if (i == 4) {
          _facelets[startIndex + i] = defaultCenters[f];
        } else {
          _facelets[startIndex + i] = _classifier!.classifyInt(samples[i]);
        }
      }
    }
  }

  /// Manually update a single sticker's color (used on Correction Screen).
  void updateFacelet(int index, int color) {
    assert(index >= 0 && index < 54);
    assert(color >= 0 && color <= 5);
    _facelets[index] = color;
    validate();
    notifyListeners();
  }

  /// Sets current active face index for preview/edit.
  void setFaceIndex(int index) {
    if (index >= 0 && index < 6) {
      _currentFaceIndex = index;
      notifyListeners();
    }
  }

  /// Rotates the 9 stickers of [faceIndex] by 90 degrees clockwise.
  void rotateFaceClockwise(int faceIndex) {
    assert(faceIndex >= 0 && faceIndex < 6);
    final start = faceIndex * 9;
    final old = List<int>.from(_facelets.sublist(start, start + 9));
    _facelets[start + 0] = old[6];
    _facelets[start + 1] = old[3];
    _facelets[start + 2] = old[0];
    _facelets[start + 3] = old[7];
    _facelets[start + 4] = old[4];
    _facelets[start + 5] = old[1];
    _facelets[start + 6] = old[8];
    _facelets[start + 7] = old[5];
    _facelets[start + 8] = old[2];

    if (_rawFaceSamples[faceIndex] != null) {
      final oldSamples = List<LabColor>.from(_rawFaceSamples[faceIndex]!);
      _rawFaceSamples[faceIndex]![0] = oldSamples[6];
      _rawFaceSamples[faceIndex]![1] = oldSamples[3];
      _rawFaceSamples[faceIndex]![2] = oldSamples[0];
      _rawFaceSamples[faceIndex]![3] = oldSamples[7];
      _rawFaceSamples[faceIndex]![4] = oldSamples[4];
      _rawFaceSamples[faceIndex]![5] = oldSamples[1];
      _rawFaceSamples[faceIndex]![6] = oldSamples[8];
      _rawFaceSamples[faceIndex]![7] = oldSamples[5];
      _rawFaceSamples[faceIndex]![8] = oldSamples[2];
    }

    validate();
    notifyListeners();
  }

  /// Rotates the 9 stickers of [faceIndex] by 90 degrees counter-clockwise.
  void rotateFaceCounterClockwise(int faceIndex) {
    assert(faceIndex >= 0 && faceIndex < 6);
    final start = faceIndex * 9;
    final old = List<int>.from(_facelets.sublist(start, start + 9));
    _facelets[start + 0] = old[2];
    _facelets[start + 1] = old[5];
    _facelets[start + 2] = old[8];
    _facelets[start + 3] = old[1];
    _facelets[start + 4] = old[4];
    _facelets[start + 5] = old[7];
    _facelets[start + 6] = old[0];
    _facelets[start + 7] = old[3];
    _facelets[start + 8] = old[6];

    if (_rawFaceSamples[faceIndex] != null) {
      final oldSamples = List<LabColor>.from(_rawFaceSamples[faceIndex]!);
      _rawFaceSamples[faceIndex]![0] = oldSamples[2];
      _rawFaceSamples[faceIndex]![1] = oldSamples[5];
      _rawFaceSamples[faceIndex]![2] = oldSamples[8];
      _rawFaceSamples[faceIndex]![3] = oldSamples[1];
      _rawFaceSamples[faceIndex]![4] = oldSamples[4];
      _rawFaceSamples[faceIndex]![5] = oldSamples[7];
      _rawFaceSamples[faceIndex]![6] = oldSamples[0];
      _rawFaceSamples[faceIndex]![7] = oldSamples[3];
      _rawFaceSamples[faceIndex]![8] = oldSamples[6];
    }

    validate();
    notifyListeners();
  }

  /// Validates the 54 facelet array using CubeValidator.
  bool validate() {
    if (!isScanComplete) {
      _validationError = const ValidationError(
        message: 'Scan not complete. Please scan all 6 faces.',
        kind: ValidationKind.wrongColorCount,
      );
      return false;
    }
    _validationError = CubeValidator.validate(_facelets);
    notifyListeners();
    return _validationError == null;
  }

  /// Resets scan state to initial.
  void reset() {
    _currentFaceIndex = 0;
    _facelets.fillRange(0, 54, -1);
    _centerLabs.fillRange(0, 6, null);
    _rawFaceSamples.fillRange(0, 6, null);
    _classifier = null;
    _validationError = null;
    notifyListeners();
  }
}
