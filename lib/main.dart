import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:asistente_pl/state/app_state.dart';
import 'package:asistente_pl/state/theme_state.dart';
import 'package:asistente_pl/theme/app_theme.dart';
import 'package:asistente_pl/screens/splash_screen.dart';
import 'package:asistente_pl/services/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = DatabaseService();
  await db.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState(db: db)),
        ChangeNotifierProvider(create: (_) => ThemeState()),
      ],
      child: const AsistentePLApp(),
    ),
  );
}

class AsistentePLApp extends StatelessWidget {
  const AsistentePLApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeState = context.watch<ThemeState>();
    return MaterialApp(
      title: 'Asistente de Decisiones',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeState.mode,
      home: const SplashScreen(),
    );
  }
}
