import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'package:homeypark_mobile_application/config/pref/preferences.dart';
import 'package:homeypark_mobile_application/screens/home_screen.dart';
import 'package:homeypark_mobile_application/screens/sign_in_screen.dart';
import 'package:homeypark_mobile_application/screens/sign_up_screen.dart';
import 'package:homeypark_mobile_application/services/iam_service.dart';

Future<void> main() async {

  WidgetsFlutterBinding.ensureInitialized();
  await preferences.init();
  await dotenv.load(fileName: ".env");
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomeScreen(), // Aquí se integra la pantalla HomeScreen
    );
  }
}