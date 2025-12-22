import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/database_service.dart';
import '../services/auth_service.dart';
import '../services/modal_loader.dart';
import '../services/network_manager.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'network_config_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final stopwatch = Stopwatch()..start();

    try {
      // Vérifier si c'est le premier démarrage
      final prefs = await SharedPreferences.getInstance();
      final isFirstRun = !prefs.containsKey('network_mode');

      if (isFirstRun) {
        // Premier démarrage : aller directement à la configuration réseau
        if (mounted) {
          Navigator.of(
            context,
          ).pushReplacement(MaterialPageRoute(builder: (context) => const NetworkConfigScreen()));
        }
        return;
      }

      // Initialiser le réseau si déjà configuré
      if (!NetworkManager.instance.isInitialized) {
        await NetworkManager.instance.initialize();
      }

      // Phase 1: Initialisation critique
      // Déterminer le mode réseau
      final networkMode = prefs.getString('network_mode') ?? 'server';

      if (networkMode == 'server') {
        // Mode SERVEUR: créer la base de données locale
        debugPrint('🖥️  Mode SERVEUR - Création base de données locale');
        await DatabaseService().initializeLocal();
      } else if (networkMode == 'client') {
        // Mode CLIENT: initialiser en mode client (pas de base locale)
        debugPrint('💻 Mode CLIENT - Aucune base locale, tout via serveur');
        final serverIp = prefs.getString('server_ip') ?? '';
        final port = int.tryParse(prefs.getString('server_port') ?? '8080') ?? 8080;
        final username = prefs.getString('username') ?? 'admin';
        final password = prefs.getString('password') ?? 'admin123';

        await DatabaseService().initializeAsClient(serverIp, port, username, password);
      }

      // Initialiser le service d'authentification
      await AuthService().initialize();

      // Phase 2: Pré-chargement en parallèle (non bloquant)
      final preloadFuture = _preloadResources();

      // Attendre un minimum de temps pour l'UX
      final minDelay = Future.delayed(const Duration(milliseconds: 800));

      // Attendre que les deux tâches soient terminées
      await Future.wait([preloadFuture, minDelay]);

      stopwatch.stop();
      debugPrint('Initialisation complétée en ${stopwatch.elapsedMilliseconds}ms');

      if (mounted) {
        // Vérifier si un utilisateur est déjà connecté
        if (AuthService().isLoggedIn) {
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const HomeScreen()));
        } else {
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const LoginScreen()));
        }
      }
    } catch (e) {
      stopwatch.stop();
      debugPrint('Erreur d\'initialisation après ${stopwatch.elapsedMilliseconds}ms: $e');

      if (mounted) {
        // Afficher un message d'erreur spécifique
        String errorMessage = 'Erreur d\'initialisation: $e';

        if (e.toString().contains('Client réseau non connecté')) {
          errorMessage = 'Impossible de se connecter au serveur.\nVérifiez la configuration réseau.';
        } else if (e.toString().contains('Database is null')) {
          errorMessage = 'Erreur de base de données.\nRedémarrez l\'application.';
        }

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Erreur d\'initialisation'),
            content: Text(errorMessage),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(
                    context,
                  ).pushReplacement(MaterialPageRoute(builder: (context) => const NetworkConfigScreen()));
                },
                child: const Text('Configuration'),
              ),
              TextButton(onPressed: () => _initializeApp(), child: const Text('Réessayer')),
            ],
          ),
        );
      }
    }
  }

  Future<void> _preloadResources() async {
    try {
      // Pré-charger les modals les plus utilisés en arrière-plan
      ModalLoader.preloadFrequentModals();
    } catch (e) {
      // Ignorer les erreurs de pré-chargement pour ne pas bloquer l'app
      debugPrint('Erreur de pré-chargement: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.business, size: 80, color: Colors.blue),
            const SizedBox(height: 20),
            const Text(
              'Gestion de Magasin',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text('Initialisation en cours...', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}
