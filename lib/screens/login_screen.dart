import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/database_service.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool isClientMode = false;

  @override
  void initState() {
    super.initState();
    _checkNetworkMode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _usernameFocus.requestFocus();
    });
  }

  Future<void> _checkNetworkMode() async {
    final prefs = await SharedPreferences.getInstance();
    final mode = prefs.getString('network_mode') ?? 'server';
    setState(() {
      isClientMode = mode == 'client';
    });
  }

  Future<void> _resetNetworkConfig() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('network_mode');
    await prefs.remove('server_ip');
    await prefs.remove('server_port');
    await prefs.remove('app_configured');

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Configuration réseau effacée. Redémarrez l\'application.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final username = _usernameController.text.trim();
      final password = _passwordController.text;

      debugPrint('🔐 LOGIN_SCREEN: Tentative de connexion pour: $username');

      // Authentification via AuthService (gère automatiquement mode Client/Serveur)
      final success = await AuthService().login(username, password);

      if (success && mounted) {
        debugPrint('✅ LOGIN_SCREEN: Connexion réussie pour: $username');
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const HomeScreen()));
      } else if (mounted) {
        debugPrint('❌ LOGIN_SCREEN: Connexion échouée pour: $username');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nom d\'utilisateur ou mot de passe incorrect'),
            backgroundColor: Colors.red,
          ),
        );
        _usernameFocus.requestFocus();
      }
    } catch (e) {
      debugPrint('❌ LOGIN_SCREEN: Erreur - $e');
      if (mounted) {
        String errorMessage = 'Erreur de connexion';
        if (e.toString().contains('SqliteException') || e.toString().contains('database')) {
          errorMessage = 'Erreur de base de données. Vérifiez la connexion au serveur.';
        } else if (e.toString().contains('Connection') || e.toString().contains('network')) {
          errorMessage = 'Impossible de se connecter au serveur. Vérifiez la configuration réseau.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.grey[300]!, Colors.grey[200]!, Colors.grey[50]!],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              width: 420,
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo et titre
                    Container(
                      padding: const EdgeInsets.only(bottom: 32),
                      child: Column(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withValues(alpha: 0.3),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.asset(
                                'assets/images/logo.png',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [Colors.grey[600]!, Colors.grey[500]!],
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Icon(Icons.store, size: 50, color: Colors.white),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              colors: [Colors.indigo[700]!, Colors.blue[600]!],
                            ).createShader(bounds),
                            child: const Text(
                              'P.O.S RALAIZANDRY J. F.',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Connectez-vous à votre compte',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Champ Username
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextFormField(
                        controller: _usernameController,
                        focusNode: _usernameFocus,
                        decoration: InputDecoration(
                          labelText: 'Nom d\'utilisateur',
                          hintText: 'Entrez votre nom d\'utilisateur',
                          prefixIcon: Container(
                            margin: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [Colors.indigo[600]!, Colors.blue[500]!]),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.person, color: Colors.white, size: 20),
                          ),
                          border: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.indigo[600]!, width: 2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez saisir votre nom d\'utilisateur';
                          }
                          return null;
                        },
                        onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Champ Mot de passe
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextFormField(
                        controller: _passwordController,
                        focusNode: _passwordFocus,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Mot de passe',
                          hintText: 'Entrez votre mot de passe',
                          prefixIcon: Container(
                            margin: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [Colors.indigo[600]!, Colors.blue[500]!]),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.lock, color: Colors.white, size: 20),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off : Icons.visibility,
                              color: Colors.grey[600],
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          border: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.indigo[600]!, width: 2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez saisir votre mot de passe';
                          }
                          return null;
                        },
                        onFieldSubmitted: (_) => _login(),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Bouton de connexion
                    Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [Colors.indigo[700]!, Colors.blue[600]!]),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.indigo.withValues(alpha: 0.4),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'SE CONNECTER',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Informations par défaut
                    // Container(
                    //   width: double.infinity,
                    //   padding: const EdgeInsets.all(16),
                    //   decoration: BoxDecoration(
                    //     gradient: LinearGradient(
                    //       colors: [Colors.blue[50]!, Colors.indigo[50]!],
                    //     ),
                    //     borderRadius: BorderRadius.circular(12),
                    //     border: Border.all(color: Colors.blue[200]!, width: 1),
                    //   ),
                    //   child: Column(
                    //     children: [
                    //       Row(
                    //         children: [
                    //           Icon(Icons.info_outline, color: Colors.blue[600], size: 18),
                    //           const SizedBox(width: 8),
                    //           Text(
                    //             'Compte par défaut',
                    //             style: TextStyle(
                    //               fontSize: 13,
                    //               fontWeight: FontWeight.bold,
                    //               color: Colors.blue[700],
                    //             ),
                    //           ),
                    //         ],
                    //       ),
                    //       const SizedBox(height: 12),
                    //       Row(
                    //         children: [
                    //           Expanded(
                    //             child: Container(
                    //               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    //               decoration: BoxDecoration(
                    //                 color: Colors.white,
                    //                 borderRadius: BorderRadius.circular(8),
                    //                 border: Border.all(color: Colors.blue[200]!),
                    //               ),
                    //               child: Row(
                    //                 children: [
                    //                   Icon(Icons.person, size: 16, color: Colors.grey[600]),
                    //                   const SizedBox(width: 8),
                    //                   const Expanded(
                    //                     child: SelectableText(
                    //                       'admin',
                    //                       style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    //                     ),
                    //                   ),
                    //                   IconButton(
                    //                     icon: Icon(Icons.copy, size: 16, color: Colors.grey[600]),
                    //                     onPressed: () {
                    //                       Clipboard.setData(const ClipboardData(text: 'admin'));
                    //                       ScaffoldMessenger.of(context).showSnackBar(
                    //                         const SnackBar(
                    //                           content: Text('Nom d\'utilisateur copié'),
                    //                           duration: Duration(seconds: 1),
                    //                         ),
                    //                       );
                    //                     },
                    //                     padding: EdgeInsets.zero,
                    //                     constraints: const BoxConstraints(),
                    //                   ),
                    //                 ],
                    //               ),
                    //             ),
                    //           ),
                    //           const SizedBox(width: 12),
                    //           Expanded(
                    //             child: Container(
                    //               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    //               decoration: BoxDecoration(
                    //                 color: Colors.white,
                    //                 borderRadius: BorderRadius.circular(8),
                    //                 border: Border.all(color: Colors.blue[200]!),
                    //               ),
                    //               child: Row(
                    //                 children: [
                    //                   Icon(Icons.lock, size: 16, color: Colors.grey[600]),
                    //                   const SizedBox(width: 8),
                    //                   const Expanded(
                    //                     child: SelectableText(
                    //                       'admin123',
                    //                       style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    //                     ),
                    //                   ),
                    //                   IconButton(
                    //                     icon: Icon(Icons.copy, size: 16, color: Colors.grey[600]),
                    //                     onPressed: () {
                    //                       Clipboard.setData(const ClipboardData(text: 'admin123'));
                    //                       ScaffoldMessenger.of(context).showSnackBar(
                    //                         const SnackBar(
                    //                           content: Text('Mot de passe copié'),
                    //                           duration: Duration(seconds: 1),
                    //                         ),
                    //                       );
                    //                     },
                    //                     padding: EdgeInsets.zero,
                    //                     constraints: const BoxConstraints(),
                    //                   ),
                    //                 ],
                    //               ),
                    //             ),
                    //           ),
                    //         ],
                    //       ),
                    //     ],
                    //   ),
                    // ),
                    // const SizedBox(height: 20),

                    // Boutons Configuration réseau
                    // if (!_isClientMode)
                    //   SizedBox(
                    //     width: double.infinity,
                    //     height: 48,
                    //     child: OutlinedButton.icon(
                    //       onPressed: () {
                    //         Navigator.of(
                    //           context,
                    //         ).push(MaterialPageRoute(builder: (context) => const NetworkConfigScreen()));
                    //       },
                    //       icon: Icon(Icons.settings, color: Colors.indigo[600]),
                    //       label: Text(
                    //         'Configuration réseau',
                    //         style: TextStyle(color: Colors.indigo[600], fontWeight: FontWeight.w600),
                    //       ),
                    //       style: OutlinedButton.styleFrom(
                    //         side: BorderSide(color: Colors.indigo[600]!, width: 1.5),
                    //         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    //       ),
                    //     ),
                    //   ),
                    const SizedBox(height: 8),
                    // Bouton Reset Configuration
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: _resetNetworkConfig,
                        icon: Icon(Icons.refresh, color: Colors.red[600]),
                        label: Text(
                          'Effacer configuration',
                          style: TextStyle(color: Colors.red[600], fontWeight: FontWeight.w600),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.red[600]!, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
