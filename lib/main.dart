import 'package:dorm_maintenance_reporter/login_page.dart';
import 'package:dorm_maintenance_reporter/dm_page.dart';
import 'home_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
  installSecurityProvider();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const AuthWrapper(),
      routes: {
        '/home': (context) => const HomePage(),
        '/login': (context) => const LoginPage(), // Define the login route here
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Check the current user
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const HomePage();
    } else {
      return const ReportViewingPage();
    }
  }
}
void installSecurityProvider() async {
  const platform = MethodChannel('com.example.providerinstaller/provider');
  
  try {
    await platform.invokeMethod('installProvider');
    print('Security provider installed successfully.');
  } on PlatformException catch (e) {
    print("Failed to install security provider: '${e.message}'.");
  }
}
