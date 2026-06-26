import 'package:flutter_test/flutter_test.dart';
import 'package:skysnap/models/prediction.dart';

void main() {
  test('Prediction confidence percent format test', () {
    const prediction = Prediction(
      label: 'Cb',
      fullName: 'Cumulonimbus',
      confidence: 0.9423,
      inferenceTimeMs: 120,
    );
    expect(prediction.confidencePercent, '94.2%');
  });

  test('Prediction topThree representation test', () {
    final topThree = [
      const Prediction(label: 'Cb', fullName: 'Cumulonimbus', confidence: 0.52, inferenceTimeMs: 50),
      const Prediction(label: 'As', fullName: 'Altostratus', confidence: 0.49, inferenceTimeMs: 50),
      const Prediction(label: 'Ci', fullName: 'Cirrus', confidence: 0.05, inferenceTimeMs: 50),
    ];

    final prediction = Prediction(
      label: 'Cb',
      fullName: 'Cumulonimbus',
      confidence: 0.52,
      inferenceTimeMs: 50,
      topThree: topThree,
    );

    expect(prediction.topThree, isNotNull);
    expect(prediction.topThree!.length, 3);
    expect(prediction.topThree![0].label, 'Cb');
    expect(prediction.topThree![1].label, 'As');
    expect(prediction.topThree![2].label, 'Ci');
    
    // Check if similarity condition matches
    final isSimilar = (prediction.topThree![0].confidence - prediction.topThree![1].confidence).abs() <= 0.05;
    expect(isSimilar, isTrue);
  });
}
