import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hotspot_hosts/models/recording_model.dart';
import 'package:hotspot_hosts/screens/experience_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive properly for Flutter
  await Hive.initFlutter();
  Hive.registerAdapter(RecordingAdapter());

  // Open box for recordings
  await Hive.openBox('recordings');

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ExperienceSelectionScreen(),
    );
  }
}
