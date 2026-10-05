import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;

class ImageConverter {
  /// Converts a [CameraImage] from the camera stream to an [img.Image].
  /// Supports YUV420 (Android/iOS default) and BGRA8888 formats.
  static img.Image convertCameraImage(CameraImage cameraImage) {
    if (cameraImage.format.group == ImageFormatGroup.yuv420) {
      return _convertYUV420(cameraImage);
    } else if (cameraImage.format.group == ImageFormatGroup.bgra8888) {
      return _convertBGRA8888(cameraImage);
    } else {
      // Fallback: create empty or attempt YUV
      return _convertYUV420(cameraImage);
    }
  }

  static img.Image _convertBGRA8888(CameraImage cameraImage) {
    final plane = cameraImage.planes[0];
    return img.Image.fromBytes(
      width: cameraImage.width,
      height: cameraImage.height,
      bytes: plane.bytes.buffer,
      order: img.ChannelOrder.bgra,
    );
  }

  static img.Image _convertYUV420(CameraImage cameraImage) {
    final width = cameraImage.width;
    final height = cameraImage.height;

    final image = img.Image(width: width, height: height);

    final yPlane = cameraImage.planes[0];
    final uPlane = cameraImage.planes[1];
    final vPlane = cameraImage.planes[2];

    final yBytes = yPlane.bytes;
    final uBytes = uPlane.bytes;
    final vBytes = vPlane.bytes;

    final yRowStride = yPlane.bytesPerRow;
    final uvRowStride = uPlane.bytesPerRow;
    final uvPixelStride = uPlane.bytesPerPixel ?? 1;

    for (int y = 0; y < height; y++) {
      final yRowOffset = y * yRowStride;
      final uvRowOffset = (y >> 1) * uvRowStride;

      for (int x = 0; x < width; x++) {
        final yVal = yBytes[yRowOffset + x];
        final uvIndex = uvRowOffset + (x >> 1) * uvPixelStride;

        final uVal = uBytes[uvIndex];
        final vVal = vBytes[uvIndex];

        // Standard YUV to RGB integer conversion
        final c = yVal - 16;
        final d = uVal - 128;
        final e = vVal - 128;

        final r = ((298 * c + 409 * e + 128) >> 8).clamp(0, 255);
        final g = ((298 * c - 100 * d - 208 * e + 128) >> 8).clamp(0, 255);
        final b = ((298 * c + 516 * d + 128) >> 8).clamp(0, 255);

        image.setPixelRgb(x, y, r, g, b);
      }
    }

    return image;
  }
}
