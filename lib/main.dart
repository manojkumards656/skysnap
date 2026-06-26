import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/tflite_service.dart';
import 'services/hive_service.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Initialize services
  final hiveService = HiveService();
  await hiveService.initialize();

  final tfliteService = TFLiteService();
  await tfliteService.loadModel();

  runApp(const SkySnapApp());
}

class SkySnapApp extends StatelessWidget {
  const SkySnapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SkySnap',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const HomeScreen(),
    );
  }
}
