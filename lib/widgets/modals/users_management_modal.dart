import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../database/database.dart';
import '../../database/database_service.dart';
import '../../services/auth_service.dart';
import '../common/tab_navigation_widget.dart';

class UsersManagementModal extends StatefulWidget {
  const UsersManagementModal({super.key});

  @override
  State<UsersManagementModal> createState() => _UsersManagementModalState();
}

class _UsersManagementModalState extends State<UsersManagementModal> with TabNavigationMixin {
  List<User> _users = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final db = DatabaseService().database;
      final users = await db.getAllUsers();
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) => handleTabNavigation(event),
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 900,
          height: 700,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black, width: 3),
            color: Colors.white,
          ),
          child: Column(
            children: [
              _buildHeader(),
              _buildToolbar(),
              _buildTable(),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[400]!, width: 1)),
        color: Colors.grey[100],
      ),
      child: Row(
        children: [
          const Icon(Icons.people, size: 24),
          const SizedBox(width: 12),
          const Text(
            'GESTION DES UTILISATEURS',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          InkWell(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.red[600],
                border: Border.all(color: Colors.black, width: 2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[300]!, width: 1)),
        color: Colors.grey[50],
      ),
      child: Row(
        children: [
          ElevatedButton.icon(
            onPressed: _addUser,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Nouvel utilisateur'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _loadUsers,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Actualiser'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
            ),
          ),
          const Spacer(),
          Text(
            'Total: ${_users.length} utilisateurs',
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  Widget _buildTable() {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey, width: 1),
        ),
        child: Column(
          children: [
            _buildTableHeader(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: _users.length,
                      itemExtent: 40,
                      itemBuilder: (context, index) {
                        final user = _users[index];
                        return _buildTableRow(user, index);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      height: 35,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 2),
        color: Colors.grey[800],
      ),
      child: Row(
        children: [
          _buildHeaderCell('NOM', 200),
          _buildHeaderCell('USERNAME', 250),
          _buildHeaderCell('RÔLE', 150),
          _buildHeaderCell('STATUT', 100),
          _buildHeaderCell('CRÉÉ LE', 120),
          _buildHeaderCell('ACTIONS', 100),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text, double width) {
    return Container(
      width: width,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: Colors.white, width: 1)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTableRow(User user, int index) {
    final bgColor = index % 2 == 0 ? Colors.white : Colors.grey[50];
    final isCurrentUser = user.id == AuthService().currentUser?.id;

    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!, width: 0.5),
          left: const BorderSide(color: Colors.black, width: 1),
          right: const BorderSide(color: Colors.black, width: 1),
        ),
      ),
      child: Row(
        children: [
          _buildCell(user.nom, 200),
          _buildCell(user.username, 250),
          _buildCell(
            user.role,
            150,
            color: _getRoleColor(user.role),
            fontWeight: FontWeight.w600,
          ),
          _buildCell(
            user.actif ? 'Actif' : 'Inactif',
            100,
            color: user.actif ? Colors.green[700] : Colors.red[700],
            fontWeight: FontWeight.w600,
          ),
          _buildCell(
            DateFormat('dd/MM/yyyy').format(user.dateCreation),
            120,
          ),
          _buildActionsCell(user, isCurrentUser),
        ],
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'Administrateur':
        return Colors.purple[700]!;
      case 'Caisse':
        return Colors.blue[700]!;
      case 'Vendeur':
        return Colors.orange[700]!;
      default:
        return Colors.grey[700]!;
    }
  }

  Widget _buildCell(
    String text,
    double width, {
    Alignment alignment = Alignment.centerLeft,
    Color? color,
    FontWeight? fontWeight,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      alignment: alignment,
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: Colors.grey, width: 0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: color ?? Colors.black87,
          fontWeight: fontWeight ?? FontWeight.normal,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildActionsCell(User user, bool isCurrentUser) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: const Icon(Icons.edit, size: 16),
            onPressed: () => _editUser(user),
            tooltip: 'Modifier',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
          ),
          if (!isCurrentUser)
            IconButton(
              icon: Icon(
                user.actif ? Icons.block : Icons.check_circle,
                size: 16,
                color: user.actif ? Colors.red : Colors.green,
              ),
              onPressed: () => _toggleUserStatus(user),
              tooltip: user.actif ? 'Désactiver' : 'Activer',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      height: 60,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey[400]!, width: 1)),
        color: Colors.grey[50],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black, width: 1),
              color: Colors.white,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.grey[700]),
                const SizedBox(width: 8),
                Text(
                  'Seuls les administrateurs peuvent gérer les utilisateurs',
                  style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[600],
              foregroundColor: Colors.white,
            ),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _addUser() {
    _showUserDialog();
  }

  void _editUser(User user) {
    _showUserDialog(user: user);
  }

  void _showUserDialog({User? user}) {
    final isEdit = user != null;
    final nomController = TextEditingController(text: user?.nom ?? '');
    final usernameController = TextEditingController(text: user?.username ?? '');
    final passwordController = TextEditingController();
    String selectedRole = user?.role ?? 'Vendeur';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'Modifier l\'utilisateur' : 'Nouvel utilisateur'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomController,
                decoration: const InputDecoration(
                  labelText: 'Nom complet',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(
                  labelText: 'Nom d\'utilisateur',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: isEdit ? 'Nouveau mot de passe (optionnel)' : 'Mot de passe',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Rôle',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'Administrateur', child: Text('Administrateur')),
                  DropdownMenuItem(value: 'Caisse', child: Text('Caisse')),
                  DropdownMenuItem(value: 'Vendeur', child: Text('Vendeur')),
                ],
                onChanged: (value) => selectedRole = value!,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => _saveUser(
              user,
              nomController.text,
              usernameController.text,
              passwordController.text,
              selectedRole,
            ),
            child: Text(isEdit ? 'Modifier' : 'Créer'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveUser(
      User? existingUser, String nom, String username, String password, String role) async {
    if (nom.isEmpty || username.isEmpty || (existingUser == null && password.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs'), backgroundColor: Colors.red),
      );
      return;
    }

    try {
      final db = DatabaseService().database;

      if (existingUser != null) {
        // Modification
        await db.updateUser(UsersCompanion(
          id: Value(existingUser.id),
          nom: Value(nom),
          username: Value(username),
          motDePasse: password.isNotEmpty ? Value(password) : Value(existingUser.motDePasse),
          role: Value(role),
          actif: Value(existingUser.actif),
          dateCreation: Value(existingUser.dateCreation),
        ));
      } else {
        // Création
        final userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
        await db.insertUser(UsersCompanion(
          id: Value(userId),
          nom: Value(nom),
          username: Value(username),
          motDePasse: Value(password),
          role: Value(role),
          actif: const Value(true),
          dateCreation: Value(DateTime.now()),
        ));
      }

      if (mounted) {
        Navigator.of(context).pop();
        _loadUsers();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(existingUser != null ? 'Utilisateur modifié' : 'Utilisateur créé'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _toggleUserStatus(User user) async {
    try {
      final db = DatabaseService().database;
      await db.toggleUserStatus(user.id, !user.actif);
      _loadUsers();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Utilisateur ${user.actif ? 'désactivé' : 'activé'}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
