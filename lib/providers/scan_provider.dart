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

  ColorClassifier? _classifier;
  ValidationError? _validationError;
  ValidationError? get validationError => _validationError;

  bool get isScanComplete => _facelets.every((color) => color >= 0 && color <= 5);

  /// Captures the 9 facelets of the current face using the 9 sampled Lab colors.
  void captureCurrentFace(List<LabColor> sampled9) {
    assert(sampled9.length == 9);

    // Center sticker is at index 4 of the 3x3 patch
    _centerLabs[_currentFaceIndex] = sampled9[4];

    // If all 6 centers are calibrated, create trained classifier; otherwise use default reference
    if (_centerLabs.every((c) => c != null)) {
      _classifier = ColorClassifier.fromCenters(_centerLabs.cast<LabColor>());
    } else {
      _classifier ??= ColorClassifier.defaultReference();
    }

    final startIndex = _currentFaceIndex * 9;
    for (int i = 0; i < 9; i++) {
      if (i == 4) {
        // Fix center sticker to its designated face color
        _facelets[startIndex + i] = defaultCenters[_currentFaceIndex];
      } else {
        _facelets[startIndex + i] = _classifier!.classifyInt(sampled9[i]);
      }
    }

    // Move to next face if not at the end
    if (_currentFaceIndex < 5) {
      _currentFaceIndex++;
    }

    validate();
    notifyListeners();
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
    _classifier = null;
    _validationError = null;
    notifyListeners();
  }
}
