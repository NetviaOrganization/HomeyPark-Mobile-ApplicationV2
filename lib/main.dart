// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'package:homeypark_mobile_application/config/pref/preferences.dart'; // Asumo que este es tu archivo de prefs
import 'package:homeypark_mobile_application/screens/home_screen.dart';
import 'package:homeypark_mobile_application/screens/sign_in_screen.dart';
import 'package:homeypark_mobile_application/services/iam_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await preferences.init();
  await dotenv.load(fileName: ".env");

  // 1. Crea e inicializa el servicio ANTES de que la app se ejecute.
  final iamService = IAMService();
  await iamService.initialize();

  // 2. Provee la instancia YA INICIALIZADA a la app.
  runApp(
    ChangeNotifierProvider.value(
      value: iamService,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HomeyPark',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      // 3. El home de la app es el AuthWrapper, que actúa como un guardián.
      home: const AuthWrapper(),
    );
  }
}

// 4. El AuthWrapper es ahora un StatelessWidget simple y eficiente.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Escucha continuamente el estado de autenticación.
    final iamService = context.watch<IAMService>();

    // No se necesita un SplashScreen aquí porque la inicialización ya ocurrió.
    // El wrapper simplemente decide qué pantalla principal mostrar.
    if (iamService.isAuthenticated) {
      return const HomeScreen();
    } else {
      return const SignInScreen();
    }
  }
}