import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:chunne_todo/screens/intro_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter("hive_box");

  // Always start with the IntroScreen
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Daily Planner',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const IntroScreen(),
    );
  }
}
