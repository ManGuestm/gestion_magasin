import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'screens/splash_screen.dart';
import 'services/modal_loader.dart';
import 'services/navigation_service.dart';
import 'services/network_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initializeApp();
  runApp(const MyApp());
}

Future<void> _initializeApp() async {
  // Configuration système
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
    DeviceOrientation.portraitUp,
  ]);

  // Initialiser le gestionnaire réseau
  await NetworkManager.instance.initialize();

  // Pré-chargement des modals fréquents
  ModalLoader.preloadFrequentModals();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestion de Magasin',
      navigatorKey: NavigationService().navigatorKey,
      theme: _buildTheme(),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('fr', 'FR'), Locale('en', 'US')],
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      primarySwatch: Colors.blue,
      useMaterial3: true,
      visualDensity: VisualDensity.compact,
      // Optimisations de performance
      splashFactory: InkRipple.splashFactory,
      // Fix SnackBar configuration
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    );
  }
}
