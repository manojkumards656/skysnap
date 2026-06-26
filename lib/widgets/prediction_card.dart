import 'package:flutter/material.dart';
import '../models/prediction.dart';
import 'circular_gauge.dart';
import 'glass_card.dart';

class PredictionCard extends StatelessWidget {
  final String label;
  final String fullName;
  final double confidence;
  final int inferenceTimeMs;
  final List<Prediction>? topThree;

  const PredictionCard({
    super.key,
    required this.label,
    required this.fullName,
    required this.confidence,
    required this.inferenceTimeMs,
    this.topThree,
  });

  @override
  Widget build(BuildContext context) {
    final hasTopThree = topThree != null && topThree!.length >= 3;

    if (hasTopThree) {
      final p1 = topThree![0];
      final p2 = topThree![1];
      final p3 = topThree![2];
      
      final bool isSimilar = (p1.confidence - p2.confidence).abs() <= 0.05;

      return GlassCard(
        padding: const EdgeInsets.all(16),
        borderRadius: 20,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Title
            const Center(
              child: Text(
                'TOP CLASSIFICATION CANDIDATES',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Podium Row — side candidates scale height by confidence ratio
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // 2nd Candidate (Left) — height scales with confidence ratio
                  Expanded(
                    flex: 3,
                    child: _buildSideCandidate(
                      prediction: p2,
                      rank: '2ND CANDIDATE',
                      heightRatio: p1.confidence > 0
                          ? (p2.confidence / p1.confidence).clamp(0.4, 1.0)
                          : 1.0,
                    ),
                  ),
                  const SizedBox(width: 8),

                  // 1st Candidate (Center - Highlighted)
                  Expanded(
                    flex: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.cyanAccent.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.cyanAccent.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.cyanAccent.withValues(alpha: 0.05),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularGauge(
                            confidence: p1.confidence,
                            size: 130,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            p1.fullName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'CODE ${p1.label}',
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.cyanAccent,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'MOST PROBABLE',
                            style: TextStyle(
                              fontSize: 7,
                              fontWeight: FontWeight.bold,
                              color: Colors.cyanAccent,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // 3rd Candidate (Right) — height scales with confidence ratio
                  Expanded(
                    flex: 3,
                    child: _buildSideCandidate(
                      prediction: p3,
                      rank: '3RD CANDIDATE',
                      heightRatio: p1.confidence > 0
                          ? (p3.confidence / p1.confidence).clamp(0.4, 1.0)
                          : 1.0,
                    ),
                  ),
                ],
              ),
            ),

            // Similarity / Mix Alert Banner
            if (isSimilar) ...[
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.amber.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.amberAccent, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "It is either ${p1.fullName} or ${p2.fullName}, or a mix of these.",
                        style: const TextStyle(
                          color: Colors.amberAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Latency Readout
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.speed, color: Colors.white54, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      'INFERENCE LATENCY: ${inferenceTimeMs}MS',
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Courier',
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return GlassCard(
      padding: const EdgeInsets.all(20),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Cloud name details
          Text(
            fullName,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'CLASSIFICATION: CODE $label',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.cyanAccent,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 20),

          // Analog Gauge Indicator
          Center(
            child: CircularGauge(
              confidence: confidence,
              size: 170,
            ),
          ),
          const SizedBox(height: 16),

          // Diagnostic readout
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.speed, color: Colors.white60, size: 14),
                const SizedBox(width: 6),
                Text(
                  'INFERENCE LATENCY: ${inferenceTimeMs}ms',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Courier',
                    color: Colors.white60,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a side candidate card whose height scales proportionally with [heightRatio].
  /// For example, if p1 confidence is 50% and p2 is 25%, heightRatio = 0.5 → half height.
  Widget _buildSideCandidate({
    required Prediction prediction,
    required String rank,
    required double heightRatio,
  }) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: FractionallySizedBox(
        heightFactor: heightRatio,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              Text(
                prediction.label,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                prediction.fullName,
                style: const TextStyle(fontSize: 10, color: Colors.white54),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              // Confidence percentage — prominent
              Text(
                '${(prediction.confidence * 100).toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  fontFamily: 'Courier',
                ),
              ),
              const SizedBox(height: 6),
              // Small confidence bar visualization
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: prediction.confidence,
                  minHeight: 3,
                  backgroundColor: Colors.white10,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.cyanAccent),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                rank,
                style: const TextStyle(
                  fontSize: 7,
                  fontWeight: FontWeight.bold,
                  color: Colors.white38,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
