import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';

import '../database/database.dart';
import '../database/database_service.dart';
import '../services/auth_service.dart';
import '../services/security_service.dart';

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _usernameController = TextEditingController();
  final _ancienMotDePasseController = TextEditingController();
  final _nouveauMotDePasseController = TextEditingController();
  final _confirmerMotDePasseController = TextEditingController();

  bool _obscureAncienMotDePasse = true;
  bool _obscureNouveauMotDePasse = true;
  bool _obscureConfirmerMotDePasse = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _chargerProfilUtilisateur();
  }

  void _chargerProfilUtilisateur() {
    final currentUser = AuthService().currentUser;
    if (currentUser != null) {
      _nomController.text = currentUser.nom;
      _usernameController.text = currentUser.username;
    }
  }

  String _crypterMotDePasse(String motDePasse) {
    return SecurityService.hashPassword(motDePasse);
  }

  Future<void> _sauvegarderProfil() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final currentUser = AuthService().currentUser!;
      final db = DatabaseService().database;

      // Vérifier l'ancien mot de passe si un nouveau est fourni
      if (_nouveauMotDePasseController.text.isNotEmpty) {
        if (!SecurityService.verifyPassword(_ancienMotDePasseController.text, currentUser.motDePasse)) {
          throw Exception('Ancien mot de passe incorrect');
        }
      }

      // Préparer les données de mise à jour
      String motDePasseFinal = currentUser.motDePasse;
      if (_nouveauMotDePasseController.text.isNotEmpty) {
        motDePasseFinal = _crypterMotDePasse(_nouveauMotDePasseController.text);
      }

      // Mettre à jour l'utilisateur
      final updatedUser = UsersCompanion(
        id: Value(currentUser.id),
        nom: Value(_nomController.text.trim()),
        username: Value(_usernameController.text.trim()),
        motDePasse: Value(motDePasseFinal),
        role: Value(currentUser.role),
        actif: Value(currentUser.actif),
        dateCreation: Value(currentUser.dateCreation),
      );

      await db.updateUser(updatedUser);

      // Mettre à jour la session
      final newUserData = await db.getUserById(currentUser.id);
      if (newUserData != null) {
        AuthService().updateCurrentUser(newUserData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil mis à jour avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Mon Profil'),
        backgroundColor: Colors.grey[100],
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Informations personnelles',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              
              // Nom complet
              TextFormField(
                controller: _nomController,
                decoration: const InputDecoration(
                  labelText: 'Nom complet',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le nom est requis';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Nom d'utilisateur
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Nom d\'utilisateur',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le nom d\'utilisateur est requis';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              const Text(
                'Changer le mot de passe (optionnel)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // Ancien mot de passe
              TextFormField(
                controller: _ancienMotDePasseController,
                obscureText: _obscureAncienMotDePasse,
                decoration: InputDecoration(
                  labelText: 'Ancien mot de passe',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureAncienMotDePasse ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscureAncienMotDePasse = !_obscureAncienMotDePasse),
                  ),
                ),
                validator: (value) {
                  if (_nouveauMotDePasseController.text.isNotEmpty && (value == null || value.isEmpty)) {
                    return 'L\'ancien mot de passe est requis pour changer le mot de passe';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Nouveau mot de passe
              TextFormField(
                controller: _nouveauMotDePasseController,
                obscureText: _obscureNouveauMotDePasse,
                decoration: InputDecoration(
                  labelText: 'Nouveau mot de passe',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureNouveauMotDePasse ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscureNouveauMotDePasse = !_obscureNouveauMotDePasse),
                  ),
                ),
                validator: (value) {
                  if (value != null && value.isNotEmpty && value.length < 6) {
                    return 'Le mot de passe doit contenir au moins 6 caractères';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Confirmer nouveau mot de passe
              TextFormField(
                controller: _confirmerMotDePasseController,
                obscureText: _obscureConfirmerMotDePasse,
                decoration: InputDecoration(
                  labelText: 'Confirmer le nouveau mot de passe',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirmerMotDePasse ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscureConfirmerMotDePasse = !_obscureConfirmerMotDePasse),
                  ),
                ),
                validator: (value) {
                  if (_nouveauMotDePasseController.text.isNotEmpty) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez confirmer le nouveau mot de passe';
                    }
                    if (value != _nouveauMotDePasseController.text) {
                      return 'Les mots de passe ne correspondent pas';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Boutons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _sauvegarderProfil,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text('Sauvegarder'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Annuler'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nomController.dispose();
    _usernameController.dispose();
    _ancienMotDePasseController.dispose();
    _nouveauMotDePasseController.dispose();
    _confirmerMotDePasseController.dispose();
    super.dispose();
  }
}