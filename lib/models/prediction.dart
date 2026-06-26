class Prediction {
  final String label;           // Abbreviation, e.g. "Cb"
  final String fullName;        // Full name, e.g. "Cumulonimbus"
  final double confidence;      // 0.0 to 1.0
  final int inferenceTimeMs;    // milliseconds elapsed during interpreter.run()
  final List<Prediction>? topThree;

  const Prediction({
    required this.label,
    required this.fullName,
    required this.confidence,
    required this.inferenceTimeMs,
    this.topThree,
  });

  /// Confidence as a percentage string, e.g. "94.2%"
  String get confidencePercent => '${(confidence * 100).toStringAsFixed(1)}%';
}
