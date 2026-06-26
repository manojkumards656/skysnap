import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import '../models/prediction.dart';
import '../utils/constants.dart';
import '../utils/image_utils.dart';

class TFLiteService {
  static final TFLiteService _instance = TFLiteService._internal();
  factory TFLiteService() => _instance;
  TFLiteService._internal();

  Interpreter? _interpreter;
  List<String> _labels = [];
  bool _isLoaded = false;
  String? _loadError;

  bool get isLoaded => _isLoaded;
  String? get loadError => _loadError;

  Future<void> loadModel() async {
    try {
      _loadError = null;
      final options = InterpreterOptions();
      bool addedGpu = false;
      
      if (Platform.isAndroid) {
        try {
          options.addDelegate(GpuDelegateV2());
          addedGpu = true;
          debugPrint('TFLite: Successfully added GpuDelegateV2 to options');
        } catch (e) {
          debugPrint('TFLite: Failed to add GpuDelegateV2: $e. Falling back to CPU options.');
        }
      }

      try {
        if (addedGpu) {
          _interpreter = await Interpreter.fromAsset(AppConstants.modelPath, options: options);
          debugPrint('TFLite: Model loaded successfully with GPU Delegate');
        } else {
          _interpreter = await Interpreter.fromAsset(AppConstants.modelPath);
          debugPrint('TFLite: Model loaded successfully (CPU)');
        }
      } catch (e) {
        debugPrint('TFLite: Failed to create interpreter with options/GPU: $e. Retrying CPU fallback...');
        _interpreter = await Interpreter.fromAsset(AppConstants.modelPath);
        debugPrint('TFLite: Model loaded successfully with CPU fallback');
      }
      
      final labelData = await rootBundle.loadString(AppConstants.labelsPath);
      _labels = labelData
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();
          
      _isLoaded = true;
    } catch (e) {
      debugPrint('Error loading TFLite model: $e');
      _loadError = e.toString();
      _isLoaded = false;
    }
  }

  Future<Prediction> predict(String imagePath) async {
    if (!_isLoaded || _interpreter == null) {
      // Attempt to reload the model just in case it wasn't loaded
      debugPrint('TFLite: Model not loaded. Attempting to load now...');
      await loadModel();
      
      if (!_isLoaded || _interpreter == null) {
        throw Exception('Model not loaded. Load error: ${_loadError ?? "Unknown failure"}');
      }
    }

    final inputBuffer = await ImageUtils.preprocessImage(imagePath);
    final input = inputBuffer.reshape([1, AppConstants.inputSize, AppConstants.inputSize, AppConstants.numChannels]);
    final output = List<double>.filled(1 * AppConstants.numClasses, 0.0).reshape([1, AppConstants.numClasses]);

    final stopwatch = Stopwatch()..start();
    _interpreter!.run(input, output);
    stopwatch.stop();

    final List<dynamic> rawScores = output[0] as List<dynamic>;
    final scores = rawScores.map((e) => (e as num).toDouble()).toList();
    
    final List<Prediction> allPredictions = [];
    for (int i = 0; i < scores.length; i++) {
      if (i < _labels.length) {
        final label = _labels[i];
        allPredictions.add(
          Prediction(
            label: label,
            fullName: AppConstants.cloudFullNames[label] ?? label,
            confidence: scores[i],
            inferenceTimeMs: stopwatch.elapsedMilliseconds,
          ),
        );
      }
    }

    // Sort descending by confidence
    allPredictions.sort((a, b) => b.confidence.compareTo(a.confidence));

    // Get top 3
    final topThree = allPredictions.take(3).toList();
    final topPrediction = topThree.isNotEmpty
        ? topThree[0]
        : Prediction(
            label: 'Unknown',
            fullName: 'Unknown',
            confidence: 0.0,
            inferenceTimeMs: stopwatch.elapsedMilliseconds,
          );

    return Prediction(
      label: topPrediction.label,
      fullName: topPrediction.fullName,
      confidence: topPrediction.confidence,
      inferenceTimeMs: stopwatch.elapsedMilliseconds,
      topThree: topThree,
    );
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isLoaded = false;
  }
}
