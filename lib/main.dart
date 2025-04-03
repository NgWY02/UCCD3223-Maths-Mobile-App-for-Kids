import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/start_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(MathFunApp());
}

class MathFunApp extends StatelessWidget {
  const MathFunApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Math Magic',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Poppins', 
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: StartScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}