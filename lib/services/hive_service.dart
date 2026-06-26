import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import '../utils/constants.dart';

class HiveService {
  static final HiveService _instance = HiveService._internal();
  factory HiveService() => _instance;
  HiveService._internal();

  Future<void> initialize() async {
    await Hive.initFlutter();
    await Hive.openBox(AppConstants.snapsBoxName);
    final box = await Hive.openBox(AppConstants.cloudBoxName);

    if (box.isEmpty) {
      await box.put('Ac', {
        'name': 'Ac',
        'fullName': 'Altocumulus',
        'description': 'Mid-level clouds appearing as white or gray patches, sheets, or layers of rounded masses. Often arranged in rows or waves.',
        'typicalAltitude': '2,000 – 6,000 m (6,500 – 20,000 ft)',
        'weatherMeaning': 'Generally fair weather, but morning altocumulus on a warm humid day can signal afternoon thunderstorms.',
        'funFact': 'Altocumulus clouds can form stunning "mackerel sky" patterns that have helped sailors predict weather for centuries.',
      });
      await box.put('As', {
        'name': 'As',
        'fullName': 'Altostratus',
        'description': 'A gray or blue-gray mid-level cloud sheet that usually covers the entire sky. Thin enough to reveal the sun as a vague bright spot.',
        'typicalAltitude': '2,000 – 6,000 m (6,500 – 20,000 ft)',
        'weatherMeaning': 'Often precedes continuous rain or snow. A reliable indicator that a warm front is approaching.',
        'funFact': 'Looking at the sun through altostratus is like looking through frosted glass — you can tell where it is, but there are no shadows on the ground.',
      });
      await box.put('Cb', {
        'name': 'Cb',
        'fullName': 'Cumulonimbus',
        'description': 'Towering vertical clouds with massive energy, extending from low altitudes to the tropopause. Often have a distinctive anvil-shaped top.',
        'typicalAltitude': '500 – 16,000 m (1,600 – 52,000 ft)',
        'weatherMeaning': 'Thunderstorms, heavy rain, hail, lightning, and occasionally tornadoes. The most dangerous cloud type for aviation.',
        'funFact': 'A single large cumulonimbus can contain 300,000 tons of water and release energy equivalent to 10 Hiroshima-sized atomic bombs.',
      });
      await box.put('Cc', {
        'name': 'Cc',
        'fullName': 'Cirrocumulus',
        'description': 'Very small, white high-altitude cloud patches arranged in ripples or grains, without shading. One of the rarest cloud types.',
        'typicalAltitude': '5,000 – 13,000 m (16,500 – 43,000 ft)',
        'weatherMeaning': 'Usually indicates fair weather. In tropical regions, may appear before a hurricane.',
        'funFact': 'Cirrocumulus create the classic "mackerel sky" — named because the pattern resembles fish scales. They rarely last longer than a few minutes.',
      });
      await box.put('Ci', {
        'name': 'Ci',
        'fullName': 'Cirrus',
        'description': 'Thin, wispy, hair-like clouds made entirely of ice crystals. Often swept into delicate filaments by high-altitude winds.',
        'typicalAltitude': '5,000 – 13,000 m (16,500 – 43,000 ft)',
        'weatherMeaning': 'Fair weather when sparse. Dense, increasing cirrus may indicate an approaching warm front with rain in 12–24 hours.',
        'funFact': 'Cirrus clouds are made entirely of ice crystals and exist at temperatures below -40°C. The wispy tails are called "fallstreaks" — ice crystals falling and evaporating.',
      });
      await box.put('Cs', {
        'name': 'Cs',
        'fullName': 'Cirrostratus',
        'description': 'A thin, transparent high-altitude veil of ice crystals that covers the sky partly or completely. Often nearly invisible.',
        'typicalAltitude': '5,000 – 13,000 m (16,500 – 43,000 ft)',
        'weatherMeaning': 'Rain or snow is likely within 12–24 hours, as cirrostratus often precedes warm fronts.',
        'funFact': 'Cirrostratus is responsible for the beautiful halos you sometimes see around the sun or moon — caused by light refracting through hexagonal ice crystals.',
      });
      await box.put('Ct', {
        'name': 'Ct',
        'fullName': 'Contrails',
        'description': 'Condensation trails left by aircraft at high altitudes. Formed when hot, humid exhaust mixes with cold ambient air, causing water vapor to freeze.',
        'typicalAltitude': '8,000 – 12,000 m (26,000 – 40,000 ft)',
        'weatherMeaning': 'Persistent, spreading contrails indicate high upper-atmosphere humidity and may signal approaching weather systems.',
        'funFact': 'Contrails that persist and spread can eventually become indistinguishable from natural cirrus clouds, and studies suggest they may affect regional climate.',
      });
      await box.put('Cu', {
        'name': 'Cu',
        'fullName': 'Cumulus',
        'description': 'Puffy, white clouds with flat bases and rounded tops, resembling cotton balls. They form due to daytime surface heating and convection.',
        'typicalAltitude': '500 – 2,000 m (1,600 – 6,500 ft)',
        'weatherMeaning': 'Small, scattered cumulus indicate fair weather. Rapidly growing cumulus (cumulus congestus) can develop into cumulonimbus thunderstorms.',
        'funFact': 'The average fair-weather cumulus cloud weighs about 500,000 kg (1.1 million pounds) — roughly the weight of 100 elephants floating in the sky.',
      });
      await box.put('Ns', {
        'name': 'Ns',
        'fullName': 'Nimbostratus',
        'description': 'A thick, dark, featureless cloud layer that blocks the sun completely. Produces continuous, widespread, moderate-to-heavy precipitation.',
        'typicalAltitude': '0 – 3,000 m (0 – 10,000 ft)',
        'weatherMeaning': 'Steady, prolonged rain or snow that can last for hours. Associated with warm fronts and large-scale weather systems.',
        'funFact': 'Nimbostratus is often so thick (up to several kilometers) that it turns day into a gloomy twilight. It is the classic "rainy day" cloud.',
      });
      await box.put('Sc', {
        'name': 'Sc',
        'fullName': 'Stratocumulus',
        'description': 'Low, lumpy, gray or white cloud patches or sheets with dark honeycomb-like gaps. Cover large areas of sky in rolling masses.',
        'typicalAltitude': '500 – 2,000 m (1,600 – 6,500 ft)',
        'weatherMeaning': 'Generally dry weather with possible light drizzle. Usually do not produce significant precipitation.',
        'funFact': 'Stratocumulus is the most common cloud type on Earth, covering about 20% of the planet\'s surface at any given time — especially over oceans.',
      });
      await box.put('St', {
        'name': 'St',
        'fullName': 'Stratus',
        'description': 'A uniform, gray, featureless low-altitude cloud layer resembling fog that does not touch the ground. Covers the sky like a blanket.',
        'typicalAltitude': '0 – 2,000 m (0 – 6,500 ft)',
        'weatherMeaning': 'Overcast skies with drizzle or mist. Rarely produces heavy rain but can reduce visibility significantly.',
        'funFact': 'Stratus clouds that touch the ground are simply called fog. The only difference between stratus and fog is altitude — if you can walk through it, it\'s fog.',
      });
    }
  }

  Map<String, dynamic>? getCloudInfo(String abbreviation) {
    final box = Hive.box(AppConstants.cloudBoxName);
    final data = box.get(abbreviation);
    if (data == null) return null;
    return Map<String, dynamic>.from(data as Map);
  }

  Future<void> saveSnap(Map<String, dynamic> snap) async {
    final box = Hive.box(AppConstants.snapsBoxName);
    await box.put(snap['id'], snap);
  }

  List<Map<String, dynamic>> getAllSnaps() {
    final box = Hive.box(AppConstants.snapsBoxName);
    final list = box.values.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    // Sort by timestamp descending
    list.sort((a, b) {
      final aTime = DateTime.tryParse(a['timestamp'] ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = DateTime.tryParse(b['timestamp'] ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });
    return list;
  }

  Future<void> deleteSnap(String id) async {
    final box = Hive.box(AppConstants.snapsBoxName);
    await box.delete(id);
  }

  int getDiscoveredCloudCount() {
    final box = Hive.box(AppConstants.snapsBoxName);
    final uniqueLabels = <String>{};
    for (final value in box.values) {
      if (value is Map) {
        final label = value['predictionLabel'];
        if (label != null) {
          uniqueLabels.add(label.toString());
        }
      }
    }
    return uniqueLabels.length;
  }

  bool isCloudDiscovered(String abbreviation) {
    final box = Hive.box(AppConstants.snapsBoxName);
    for (final value in box.values) {
      if (value is Map) {
        if (value['predictionLabel'] == abbreviation) {
          return true;
        }
      }
    }
    return false;
  }

  String? getDiscoveredCloudImage(String abbreviation) {
    final box = Hive.box(AppConstants.snapsBoxName);
    for (final value in box.values) {
      if (value is Map) {
        if (value['predictionLabel'] == abbreviation) {
          return value['imagePath'] as String?;
        }
      }
    }
    return null;
  }
}
