import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show compute;
import 'package:image/image.dart' as img;
import '../utils/constants.dart';

class ImageUtils {
  /// Center crops the image to a square
  static img.Image centerCrop(img.Image image) {
    final int cropSize = image.width < image.height ? image.width : image.height;
    final int offsetX = (image.width - cropSize) ~/ 2;
    final int offsetY = (image.height - cropSize) ~/ 2;
    return img.copyCrop(image, x: offsetX, y: offsetY, width: cropSize, height: cropSize);
  }

  /// Preprocesses image from path for TFLite model input (384x384 RGB normalized to [0, 1]).
  ///
  /// Runs in a background isolate via [compute] to avoid blocking the UI thread
  /// during file I/O, JPEG decoding, and pixel iteration.
  static Future<Float32List> preprocessImage(String imagePath) {
    return compute(_preprocessImageIsolate, imagePath);
  }

  /// Isolate-safe top-level-compatible preprocessing function.
  /// Reads the image, center-crops, resizes, and normalizes pixel values to [0, 1].
  static Float32List _preprocessImageIsolate(String imagePath) {
    final bytes = File(imagePath).readAsBytesSync();
    final img.Image? decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw Exception('Failed to decode image');
    }

    final cropped = centerCrop(decoded);
    final resized = img.copyResize(
      cropped,
      width: AppConstants.inputSize,
      height: AppConstants.inputSize,
      interpolation: img.Interpolation.linear,
    );

    final Float32List buffer = Float32List(1 * AppConstants.inputSize * AppConstants.inputSize * AppConstants.numChannels);
    int pixelIndex = 0;
    
    for (int y = 0; y < AppConstants.inputSize; y++) {
      for (int x = 0; x < AppConstants.inputSize; x++) {
        final pixel = resized.getPixel(x, y);
        buffer[pixelIndex++] = pixel.r.toDouble();
        buffer[pixelIndex++] = pixel.g.toDouble();
        buffer[pixelIndex++] = pixel.b.toDouble();
      }
    }

    return buffer;
  }
}
