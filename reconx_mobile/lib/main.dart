import 'package:flutter/material.dart';
import 'utils/app_theme.dart';
import 'screens/home_screen.dart';
import 'services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService.init();
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
