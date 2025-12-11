import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'screens/splash_screen.dart';
import 'services/audit_service.dart';
import 'services/backup_service.dart';
import 'services/config_service.dart';
import 'services/keyboard_service.dart';
import 'services/modal_loader.dart';
import 'services/navigation_service.dart';
import 'services/network_manager.dart';
import 'services/notification_service.dart';
import 'services/theme_service.dart';

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

  // Initialiser le service d'audit
  await AuditService().initialize();

  // Initialiser le service de thème
  await ThemeService().initialize();

  // Enregistrer les raccourcis clavier
  KeyboardService.registerDefaultShortcuts();

  // Initialiser le service de configuration
  await ConfigService().initialize();

  // Initialiser le service de notifications
  NotificationService().initialize();

  // Démarrer la sauvegarde automatique
  if (ConfigService().autoBackupEnabled) {
    BackupService().startAutoBackup(interval: Duration(hours: ConfigService().autoBackupIntervalHours));
  }

  // Pré-chargement des modals fréquents
  ModalLoader.preloadFrequentModals();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return KeyboardShortcutHandler(
      child: MaterialApp(
        title: 'Gestion de Magasin',
        navigatorKey: NavigationService().navigatorKey,
        theme: ThemeService.theme,
        home: const SplashScreen(),
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('fr', 'FR'), Locale('en', 'US')],
      ),
    );
  }
}
