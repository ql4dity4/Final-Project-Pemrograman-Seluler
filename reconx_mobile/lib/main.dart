import 'package:flutter/material.dart';
import 'utils/app_theme.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ReconXApp());
}

class ReconXApp extends StatelessWidget {
  const ReconXApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ReconX Mobile',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const HomeScreen(),
    );
  }
}
