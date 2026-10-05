import 'dart:math';

class LabColor {
  final double l; // 0 to 100
  final double a; // -128 to 127
  final double b; // -128 to 127

  const LabColor(this.l, this.a, this.b);

  /// Euclidean distance in CIELAB color space (Delta E).
  double distanceTo(LabColor other) {
    final dl = l - other.l;
    final da = a - other.a;
    final db = b - other.b;
    return sqrt(dl * dl + da * da + db * db);
  }

  /// Converts standard RGB values [0..255] to LabColor using D65 reference white.
  factory LabColor.fromRGB(int r, int g, int b) {
    // 1. Normalize and linearize sRGB
    double lr = _linearize(r / 255.0);
    double lg = _linearize(g / 255.0);
    double lb = _linearize(b / 255.0);

    // 2. Convert to XYZ (D65 illuminant)
    double x = (lr * 0.4124564 + lg * 0.3575761 + lb * 0.1804375) / 0.95047;
    double y = (lr * 0.2126729 + lg * 0.7151522 + lb * 0.0721750) / 1.00000;
    double z = (lr * 0.0193339 + lg * 0.1191920 + lb * 0.9503041) / 1.08883;

    // 3. Convert XYZ to LAB
    double fx = _f(x);
    double fy = _f(y);
    double fz = _f(z);

    double lVal = (116.0 * fy) - 16.0;
    double aVal = 500.0 * (fx - fy);
    double bVal = 200.0 * (fy - fz);

    return LabColor(lVal, aVal, bVal);
  }

  static double _linearize(double c) {
    return (c > 0.04045) ? pow((c + 0.055) / 1.055, 2.4).toDouble() : (c / 12.92);
  }

  static double _f(double t) {
    const double delta = 6.0 / 29.0;
    if (t > delta * delta * delta) {
      return pow(t, 1.0 / 3.0).toDouble();
    } else {
      return (t / (3.0 * delta * delta)) + (4.0 / 29.0);
    }
  }

  @override
  String toString() => 'LabColor(L: ${l.toStringAsFixed(1)}, a: ${a.toStringAsFixed(1)}, b: ${b.toStringAsFixed(1)})';
}
