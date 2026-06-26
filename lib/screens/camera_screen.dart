import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import '../services/camera_service.dart';
import '../services/tflite_service.dart';
import '../services/hive_service.dart';
import '../widgets/capture_button.dart';
import '../widgets/guess_textfield.dart';
import '../widgets/glass_card.dart';
import 'result_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with TickerProviderStateMixin, WidgetsBindingObserver {
  final CameraService _cameraService = CameraService();
  final TFLiteService _tfliteService = TFLiteService();
  final HiveService _hiveService = HiveService();
  final TextEditingController _guessController = TextEditingController();
  
  bool _isProcessing = false;
  String? _capturedImagePath;
  bool _hasCaptured = false;

  // Zoom configuration
  double _minZoomLevel = 1.0;
  double _maxZoomLevel = 1.0;
  double _currentZoomLevel = 1.0;
  bool get _isZoomSupported => _maxZoomLevel > _minZoomLevel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      await _cameraService.initialize();
      if (_cameraService.controller != null) {
        _minZoomLevel = await _cameraService.controller!.getMinZoomLevel();
        _maxZoomLevel = await _cameraService.controller!.getMaxZoomLevel();
      }
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _cameraService.controller;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      _cameraService.dispose();
      if (mounted) {
        setState(() {});
      }
    } else if (state == AppLifecycleState.resumed) {
      _initializeServices();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraService.dispose();
    _guessController.dispose();
    super.dispose();
  }

  Future<void> _capturePhoto() async {
    if (_isProcessing) return;

    try {
      final tempPath = await _cameraService.captureImage();
      
      // Save permanently to application documents directory
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'snap_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final permanentPath = '${appDir.path}/$fileName';
      await File(tempPath).copy(permanentPath);

      setState(() {
        _capturedImagePath = permanentPath;
        _hasCaptured = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to capture photo: $e')),
        );
      }
    }
  }

  Future<void> _analyzeAndSave() async {
    if (_capturedImagePath == null || _isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final imagePath = _capturedImagePath!;
      final prediction = await _tfliteService.predict(imagePath);
      final cloudInfo = _hiveService.getCloudInfo(prediction.label);
      final userGuess = _guessController.text.trim();

      // Check correctness
      bool isCorrect = false;
      if (userGuess.isNotEmpty) {
        final guess = userGuess.toLowerCase().trim();
        final label = prediction.label.toLowerCase();
        final fullName = prediction.fullName.toLowerCase();
        isCorrect = (guess == label || guess == fullName);
      }

      // Save to snaps box
      final snapId = DateTime.now().millisecondsSinceEpoch.toString();
      final snap = {
        'id': snapId,
        'imagePath': imagePath,
        'predictionLabel': prediction.label,
        'predictionFullName': prediction.fullName,
        'confidence': prediction.confidence,
        'inferenceTimeMs': prediction.inferenceTimeMs,
        'topThree': prediction.topThree?.map((p) {
          return <String, dynamic>{
            'label': p.label,
            'fullName': p.fullName,
            'confidence': p.confidence,
          };
        }).toList(),
        'userGuess': userGuess,
        'isCorrect': isCorrect,
        'timestamp': DateTime.now().toIso8601String(),
      };

      await _hiveService.saveSnap(snap);

      if (mounted) {
        setState(() {
          _isProcessing = false;
        });

        // Navigate directly to result screen, replacing the camera screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ResultScreen(
              imagePath: imagePath,
              prediction: prediction,
              cloudInfo: cloudInfo,
              userGuess: userGuess,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Inference Error: ${e.toString()}')),
        );
      }
    }
  }

  Widget _buildSquareCameraView(BuildContext context, BoxConstraints constraints) {
    final controller = _cameraService.controller;
    if (controller == null || !_cameraService.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    final double width = constraints.maxWidth;
    return ClipRect(
      child: SizedBox(
        width: width,
        height: width, // Force square layout
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Viewfinder preview
            OverflowBox(
              alignment: Alignment.center,
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: width,
                  height: width * controller.value.aspectRatio,
                  child: CameraPreview(controller),
                ),
              ),
            ),

            // Scientific Grid overlays
            CustomPaint(
              painter: _HUDGridPainter(),
            ),

            // Zoom Slider Overlay
            if (_isZoomSupported)
              Positioned(
                bottom: 12,
                left: 16,
                right: 16,
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  borderRadius: 12,
                  child: Row(
                    children: [
                      Text(
                        '${_minZoomLevel.toStringAsFixed(0)}x',
                        style: const TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.bold),
                      ),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: Colors.cyanAccent,
                            inactiveTrackColor: Colors.white24,
                            thumbColor: Colors.cyanAccent,
                            overlayColor: Colors.cyanAccent.withValues(alpha: 0.2),
                            trackHeight: 2.0,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
                          ),
                          child: Slider(
                            value: _currentZoomLevel,
                            min: _minZoomLevel,
                            max: _maxZoomLevel,
                            onChanged: (value) async {
                              setState(() {
                                _currentZoomLevel = value;
                              });
                              await controller.setZoomLevel(value);
                            },
                          ),
                        ),
                      ),
                      Text(
                        '${_currentZoomLevel.toStringAsFixed(1)}x',
                        style: const TextStyle(fontSize: 10, color: Colors.cyanAccent, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070612), // Twilight base
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'CLOUD RADAR HUD',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
            color: Colors.cyanAccent,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Upper dashboard readout
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    child: GlassCard(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      borderRadius: 12,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.greenAccent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'RADAR ACTIVE',
                                style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                              ),
                            ],
                          ),
                          const Text(
                            'EFNETV2-S // 384x384',
                            style: TextStyle(color: Colors.cyanAccent, fontSize: 10, fontFamily: 'Courier', fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Square Viewport (Live camera or captured static preview)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white12, width: 2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: _hasCaptured
                            ? AspectRatio(
                                aspectRatio: 1.0,
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.file(File(_capturedImagePath!), fit: BoxFit.cover),
                                    
                                    // Scanning overlay during processing
                                    if (_isProcessing) ...[
                                      Container(color: Colors.black45),
                                    ],
                                  ],
                                ),
                              )
                            : _buildSquareCameraView(context, constraints),
                      ),
                    ),
                  ),

                  // Lower controls (Capture button vs Guessing inputs)
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: _hasCaptured
                        ? _isProcessing
                            ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 30),
                                child: Column(
                                  children: [
                                    CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.redAccent)),
                                    SizedBox(height: 16),
                                    Text(
                                      'DECRYPTING CLOUD CONTOUR...',
                                      style: TextStyle(
                                        color: Colors.redAccent,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 2,
                                        fontFamily: 'Courier',
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'GUESS THE CLOUD CONTROLLER',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  GuessTextField(controller: _guessController),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: _analyzeAndSave,
                                          style: OutlinedButton.styleFrom(
                                            side: const BorderSide(color: Colors.white30),
                                            padding: const EdgeInsets.symmetric(vertical: 16),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                          ),
                                          child: const Text('SKIP GUESS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: _analyzeAndSave,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.cyanAccent,
                                            foregroundColor: Colors.black,
                                            padding: const EdgeInsets.symmetric(vertical: 16),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                          ),
                                          child: const Text('ANALYZE', style: TextStyle(fontWeight: FontWeight.bold)),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  TextButton(
                                    onPressed: () {
                                      // Delete the orphaned permanent image file to avoid storage leaks
                                      if (_capturedImagePath != null) {
                                        final file = File(_capturedImagePath!);
                                        if (file.existsSync()) {
                                          file.deleteSync();
                                        }
                                      }
                                      setState(() {
                                        _capturedImagePath = null;
                                        _hasCaptured = false;
                                        _guessController.clear();
                                      });
                                    },
                                    child: const Text(
                                      'Retake Photo',
                                      style: TextStyle(color: Colors.white54, fontSize: 13, decoration: TextDecoration.underline),
                                    ),
                                  ),
                                ],
                              )
                        : Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Column(
                              children: [
                                const Text(
                                  'ALIGN CLOUD CONTOUR WITHIN TARGET RETICLE',
                                  style: TextStyle(
                                    color: Colors.white38,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                CaptureButton(
                                  onPressed: _capturePhoto,
                                  isLoading: false,
                                ),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HUDGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..strokeWidth = 1.0;

    // Draw third dividers (Rule of Thirds HUD)
    final double thirdWidth = size.width / 3;
    final double thirdHeight = size.height / 3;

    canvas.drawLine(Offset(thirdWidth, 0), Offset(thirdWidth, size.height), paint);
    canvas.drawLine(Offset(thirdWidth * 2, 0), Offset(thirdWidth * 2, size.height), paint);

    canvas.drawLine(Offset(0, thirdHeight), Offset(size.width, thirdHeight), paint);
    canvas.drawLine(Offset(0, thirdHeight * 2), Offset(size.width, thirdHeight * 2), paint);

    // Draw Corner Scientific Brackets
    final bracketPaint = Paint()
      ..color = Colors.white38
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    const double bracketSize = 16.0;

    // Top Left
    canvas.drawPath(
      Path()
        ..moveTo(bracketSize, 0)
        ..lineTo(0, 0)
        ..lineTo(0, bracketSize),
      bracketPaint,
    );
    // Top Right
    canvas.drawPath(
      Path()
        ..moveTo(size.width - bracketSize, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width, bracketSize),
      bracketPaint,
    );
    // Bottom Left
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height - bracketSize)
        ..lineTo(0, size.height)
        ..lineTo(bracketSize, size.height),
      bracketPaint,
    );
    // Bottom Right
    canvas.drawPath(
      Path()
        ..moveTo(size.width - bracketSize, size.height)
        ..lineTo(size.width, size.height)
        ..lineTo(size.width, size.height - bracketSize),
      bracketPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
