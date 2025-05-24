import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/registration_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize FFI for desktop platforms only
  // if (!kIsWeb) {
  //   try {
  //     if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
  //       sqfliteFfiInit();
  //       databaseFactory = databaseFactoryFfi;
  //     }
  //   } catch (e) {
  //     debugPrint('Error initializing database: $e');
  //   }
  // }

  // Create the ProviderContainer to access providers
  final container = ProviderContainer();

  // Check and create monthly payments if needed

  runApp(UncontrolledProviderScope(
    container: container,
    child: const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'School Bus Payment Tracker',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
      ),
      // home: const LoginScreen(),
      initialRoute: '/login',
      routes: {
    '/login': (context) => const LoginScreen(),
    '/register': (context) => const RegistrationScreen(),
  },
    );
  }
}
