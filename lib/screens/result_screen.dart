import 'dart:io';
import 'package:flutter/material.dart';
import '../models/prediction.dart';
import '../widgets/prediction_card.dart';
import '../widgets/altitude_chart.dart';
import '../widgets/glass_card.dart';
import '../services/hive_service.dart';

class ResultScreen extends StatelessWidget {
  final String? snapId;
  final String imagePath;
  final Prediction prediction;
  final Map<String, dynamic>? cloudInfo;
  final String userGuess;
  final bool isHistoryView;

  const ResultScreen({
    super.key,
    this.snapId,
    required this.imagePath,
    required this.prediction,
    this.cloudInfo,
    required this.userGuess,
    this.isHistoryView = false,
  });

  bool _isGuessCorrect() {
    if (userGuess.isEmpty) return false;
    final guess = userGuess.toLowerCase().trim();
    final label = prediction.label.toLowerCase();
    final fullName = prediction.fullName.toLowerCase();
    return guess == label || guess == fullName;
  }

  void _deleteFromResultScreen(BuildContext context) async {
    if (snapId == null) return;
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2C),
        title: const Text('Delete Snap', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to delete this cloud snap from your journal?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await HiveService().deleteSnap(snapId!);
      if (context.mounted) {
        Navigator.pop(context); // return back to dashboard
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCorrect = _isGuessCorrect();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF070512), // Midnight Indigo
              Color(0xFF0F0C2A), // Twilight Purple
              Color(0xFF06050F), // Dark Space
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom top bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text(
                      isHistoryView ? 'JOURNAL LOG' : 'SCAN COMPLETION',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    isHistoryView
                        ? IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                            onPressed: () => _deleteFromResultScreen(context),
                          )
                        : const SizedBox(width: 48), // Spacer to center title
                  ],
                ),
              ),

              // Main scrollable content
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Captured image display inside a styled frame
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white12, width: 1.5),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Image.file(
                            File(imagePath),
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: 250,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Low confidence alert
                      if (prediction.confidence < 0.3) ...[
                        GlassCard(
                          color: Colors.amber.withValues(alpha: 0.1),
                          border: Border.all(color: Colors.amber.withValues(alpha: 0.4), width: 1),
                          padding: const EdgeInsets.all(14),
                          child: const Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 24),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Low confidence reading. The cloud pattern might be ambiguous or obscured.',
                                  style: TextStyle(
                                    color: Colors.amber,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // 2. Prediction card widget (includes Circular Gauge)
                      PredictionCard(
                        label: prediction.label,
                        fullName: prediction.fullName,
                        confidence: prediction.confidence,
                        inferenceTimeMs: prediction.inferenceTimeMs,
                        topThree: prediction.topThree,
                      ),
                      const SizedBox(height: 16),

                      // 3. User guess evaluation card
                      GlassCard(
                        color: isCorrect
                            ? Colors.green.withValues(alpha: 0.08)
                            : userGuess.isEmpty
                                ? Colors.white.withValues(alpha: 0.04)
                                : Colors.red.withValues(alpha: 0.08),
                        border: Border.all(
                          color: isCorrect
                              ? Colors.greenAccent.withValues(alpha: 0.3)
                              : userGuess.isEmpty
                                  ? Colors.white12
                                  : Colors.redAccent.withValues(alpha: 0.3),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(
                              isCorrect
                                  ? Icons.check_circle_outline
                                  : userGuess.isEmpty
                                      ? Icons.help_outline
                                      : Icons.highlight_off,
                              color: isCorrect
                                  ? Colors.greenAccent
                                  : userGuess.isEmpty
                                      ? Colors.white38
                                      : Colors.redAccent,
                              size: 28,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isCorrect
                                        ? 'Guessed Correctly!'
                                        : userGuess.isEmpty
                                            ? 'No Guess Registered'
                                            : 'Incorrect Prediction Guess',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: isCorrect
                                          ? Colors.greenAccent
                                          : userGuess.isEmpty
                                              ? Colors.white70
                                              : Colors.redAccent,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    userGuess.isNotEmpty
                                        ? 'Your Entry: "$userGuess"'
                                        : 'You can test your cloud knowledge on future radar snaps.',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 4. Meteorological Altitude Chart
                      AltitudeChart(activeCloudLabel: prediction.label),
                      const SizedBox(height: 20),

                      // 5. Cloud scientific descriptions
                      if (cloudInfo != null) ...[
                        const Padding(
                          padding: EdgeInsets.only(left: 4.0, bottom: 10.0),
                          child: Text(
                            'METEOROLOGICAL SPECIFICATIONS',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.cyanAccent,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                        _infoCard(Icons.info_outline, 'Description', cloudInfo!['description']),
                        _infoCard(Icons.category_outlined, 'Cloud Family / Altitude Layer', cloudInfo!['family']),
                        _infoCard(Icons.science_outlined, 'Physical Composition', cloudInfo!['composition']),
                        _infoCard(Icons.air_outlined, 'Formation Mechanism', cloudInfo!['formation']),
                        _infoCard(Icons.grain_outlined, 'Precipitation Potential', cloudInfo!['precipitation']),
                        _infoCard(Icons.height, 'Atmospheric Level', cloudInfo!['typicalAltitude']),
                        _infoCard(Icons.umbrella_outlined, 'Weather Pattern Indication', cloudInfo!['weatherMeaning']),
                        _infoCard(Icons.wb_sunny_outlined, 'Scientific Fact', cloudInfo!['funFact']),
                      ],
                      const SizedBox(height: 24),

                      // Navigation Button at bottom
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(isHistoryView ? Icons.history : Icons.dashboard_outlined, color: Colors.black),
                          label: Text(
                            isHistoryView ? 'RETURN TO JOURNAL' : 'BACK TO DASHBOARD',
                            style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.cyanAccent,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoCard(IconData icon, String title, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.cyanAccent, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.cyanAccent,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value ?? 'Unknown',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white70,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
