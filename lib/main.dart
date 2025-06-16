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

    return ChangeNotifierProvider(
      create: (context) => IAMService(),
      child: MaterialApp(
        title: 'HomeyPark',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue), 
          useMaterial3: true,
        ),
        
        home: const AuthWrapper(), 
        routes: {
          '/signin': (context) => const SignInScreen(),
          '/signup': (context) => const SignUpScreen(),
          '/home': (context) => const HomeScreen(),
        },
       
        onGenerateRoute: (settings) {
          return MaterialPageRoute(
            builder: (context) => Scaffold(
              appBar: AppBar(title: const Text('Error')),
              body: Center(
                child: Text('Ruta no encontrada: ${settings.name}'),
              ),
            ),
          );
        },
      ),
    );
  }
}



class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();

    Provider.of<IAMService>(context, listen: false).initialize();
  }

  @override
  Widget build(BuildContext context) {

    return Consumer<IAMService>(
      builder: (context, iamService, child) {

        if (iamService.isLoading) {
          return const SplashScreen();
        } else if (iamService.isAuthenticated) {
          return const HomeScreen();
        } else {
          return const SignInScreen();
        }
      },
    );
  }
}


class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Initializing...'),
          ],
        ),
      ),
    );
  }
}