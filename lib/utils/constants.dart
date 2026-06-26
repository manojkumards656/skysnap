class AppConstants {
  // Asset paths
  static const String modelPath = 'assets/skysnap_v2_heavy.tflite';
  static const String labelsPath = 'assets/labels_v2.txt';

  // Model input configuration
  static const int inputSize = 384;           // 384x384 pixels
  static const int numChannels = 3;           // RGB
  static const int numClasses = 11;           // number of cloud types
  static const double normalizationFactor = 255.0;

  // Hive box names
  static const String cloudBoxName = 'cloudKnowledge';
  static const String snapsBoxName = 'userSnaps';

  // Cloud full names — maps label abbreviation to human-readable name
  static const Map<String, String> cloudFullNames = {
    'Ac': 'Altocumulus',
    'As': 'Altostratus',
    'Cb': 'Cumulonimbus',
    'Cc': 'Cirrocumulus',
    'Ci': 'Cirrus',
    'Cs': 'Cirrostratus',
    'Ct': 'Contrails',
    'Cu': 'Cumulus',
    'Ns': 'Nimbostratus',
    'Sc': 'Stratocumulus',
    'St': 'Stratus',
  };
}
