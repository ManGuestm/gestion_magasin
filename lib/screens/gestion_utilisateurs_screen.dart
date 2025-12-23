import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';

import '../database/database.dart';
import '../database/database_service.dart';
import '../services/auth_service.dart';
import '../services/security_service.dart';

class GestionUtilisateursScreen extends StatefulWidget {
  const GestionUtilisateursScreen({super.key});

  @override
  State<GestionUtilisateursScreen> createState() => _GestionUtilisateursScreenState();
}

class _GestionUtilisateursScreenState extends State<GestionUtilisateursScreen> {
  List<User> _utilisateurs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _chargerUtilisateurs();
  }

  Future<void> _chargerUtilisateurs() async {
    setState(() => _isLoading = true);
    try {
      final db = DatabaseService().database;
      final utilisateurs = await db.getAllUsers();
      setState(() {
        _utilisateurs = utilisateurs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red));
      }
    }
  }

  String _crypterMotDePasse(String motDePasse) {
    return SecurityService.hashPassword(motDePasse);
  }

  void _ajouterUtilisateur() {
    _afficherDialogueUtilisateur();
  }

  void _modifierUtilisateur(User utilisateur) {
    _afficherDialogueUtilisateur(utilisateur: utilisateur);
  }

  void _afficherDialogueUtilisateur({User? utilisateur}) {
    final isModification = utilisateur != null;
    final nomController = TextEditingController(text: utilisateur?.nom ?? '');
    final usernameController = TextEditingController(text: utilisateur?.username ?? '');
    final motDePasseController = TextEditingController();
    String roleSelectionne = utilisateur?.role ?? 'Vendeur';
    bool actif = utilisateur?.actif ?? true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isModification ? 'Modifier l\'utilisateur' : 'Nouvel utilisateur'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nomController,
                  decoration: const InputDecoration(labelText: 'Nom complet', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom d\'utilisateur',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: motDePasseController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: isModification ? 'Nouveau mot de passe (optionnel)' : 'Mot de passe',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: roleSelectionne,
                  decoration: const InputDecoration(labelText: 'Rôle', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'Administrateur', child: Text('Administrateur')),
                    DropdownMenuItem(value: 'Caisse', child: Text('Caisse')),
                    DropdownMenuItem(value: 'Vendeur', child: Text('Vendeur')),
                    DropdownMenuItem(value: 'Consultant', child: Text('Consultant')),
                  ],
                  onChanged: (value) => setDialogState(() => roleSelectionne = value!),
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: const Text('Compte actif'),
                  value: actif,
                  onChanged: (value) => setDialogState(() => actif = value!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () => _sauvegarderUtilisateur(
                context,
                utilisateur,
                nomController.text,
                usernameController.text,
                motDePasseController.text,
                roleSelectionne,
                actif,
              ),
              child: Text(isModification ? 'Modifier' : 'Créer'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sauvegarderUtilisateur(
    BuildContext dialogContext,
    User? utilisateurExistant,
    String nom,
    String username,
    String motDePasse,
    String role,
    bool actif,
  ) async {
    if (nom.trim().isEmpty || username.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nom et nom d\'utilisateur requis'), backgroundColor: Colors.red),
      );
      return;
    }

    if (utilisateurExistant == null && motDePasse.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mot de passe requis pour un nouvel utilisateur'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final navigator = Navigator.of(dialogContext);
      final db = DatabaseService().database;

      if (utilisateurExistant == null) {
        // Nouvel utilisateur
        final id = 'user_${DateTime.now().millisecondsSinceEpoch}';
        await db.insertUser(
          UsersCompanion(
            id: Value(id),
            nom: Value(nom.trim()),
            username: Value(username.trim()),
            motDePasse: Value(_crypterMotDePasse(motDePasse)),
            role: Value(role),
            actif: Value(actif),
            dateCreation: Value(DateTime.now()),
          ),
        );
      } else {
        // Modification
        String motDePasseFinal = utilisateurExistant.motDePasse;
        if (motDePasse.trim().isNotEmpty) {
          motDePasseFinal = _crypterMotDePasse(motDePasse);
        }

        await db.updateUser(
          UsersCompanion(
            id: Value(utilisateurExistant.id),
            nom: Value(nom.trim()),
            username: Value(username.trim()),
            motDePasse: Value(motDePasseFinal),
            role: Value(role),
            actif: Value(actif),
            dateCreation: Value(utilisateurExistant.dateCreation),
          ),
        );
      }

      navigator.pop();
      await _chargerUtilisateurs();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(utilisateurExistant == null ? 'Utilisateur créé' : 'Utilisateur modifié'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _supprimerUtilisateur(User utilisateur) async {
    final currentUser = AuthService().currentUser;
    if (currentUser?.id == utilisateur.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de supprimer votre propre compte'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Êtes-vous sûr de vouloir supprimer l\'utilisateur "${utilisateur.nom}" ?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirme == true) {
      try {
        final db = DatabaseService().database;
        await db.deleteUser(utilisateur.id);
        await _chargerUtilisateurs();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Utilisateur supprimé'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Gestion des utilisateurs'),
        backgroundColor: Colors.grey[100],
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          IconButton(
            onPressed: _ajouterUtilisateur,
            icon: const Icon(Icons.add),
            tooltip: 'Ajouter un utilisateur',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _utilisateurs.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Aucun utilisateur trouvé', style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // En-tête
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.people, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          '${_utilisateurs.length} utilisateur(s)',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Liste des utilisateurs
                  Expanded(
                    child: ListView.builder(
                      itemCount: _utilisateurs.length,
                      itemBuilder: (context, index) {
                        final utilisateur = _utilisateurs[index];
                        final currentUser = AuthService().currentUser;
                        final isCurrentUser = currentUser?.id == utilisateur.id;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: utilisateur.actif ? Colors.green : Colors.grey,
                              child: Text(
                                utilisateur.nom.isNotEmpty ? utilisateur.nom[0].toUpperCase() : 'U',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Row(
                              children: [
                                Text(utilisateur.nom, style: const TextStyle(fontWeight: FontWeight.bold)),
                                if (isCurrentUser) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.blue,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Text(
                                      'Vous',
                                      style: TextStyle(color: Colors.white, fontSize: 10),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Username: ${utilisateur.username}'),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _getRoleColor(utilisateur.role),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        utilisateur.role,
                                        style: const TextStyle(color: Colors.white, fontSize: 12),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      utilisateur.actif ? 'Actif' : 'Inactif',
                                      style: TextStyle(
                                        color: utilisateur.actif ? Colors.green : Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: () => _modifierUtilisateur(utilisateur),
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  tooltip: 'Modifier',
                                ),
                                if (!isCurrentUser)
                                  IconButton(
                                    onPressed: () => _supprimerUtilisateur(utilisateur),
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    tooltip: 'Supprimer',
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'Administrateur':
        return Colors.red;
      case 'Caisse':
        return Colors.orange;
      case 'Vendeur':
        return Colors.green;
      case 'Consultant':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}
