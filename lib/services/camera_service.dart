import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';

class CameraService {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;

  CameraController? get controller => _controller;
  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        throw Exception('No cameras found');
      }

      final backCamera = _cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );

      _controller = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();
      _isInitialized = true;
    } on CameraException catch (e) {
      debugPrint('CameraException during initialization: ${e.description}');
      _isInitialized = false;
      rethrow;
    } catch (e) {
      debugPrint('General exception during camera initialization: $e');
      _isInitialized = false;
      rethrow;
    }
  }

  Future<String> captureImage() async {
    if (!_isInitialized || _controller == null) {
      throw Exception('Camera not initialized');
    }
    try {
      final XFile file = await _controller!.takePicture();
      return file.path;
    } catch (e) {
      debugPrint('Failed to capture image: $e');
      rethrow;
    }
  }

  void dispose() {
    _controller?.dispose();
    _controller = null;
    _isInitialized = false;
  }
}
