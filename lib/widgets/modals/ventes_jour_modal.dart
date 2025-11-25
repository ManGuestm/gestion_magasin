import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';

import '../../database/database_service.dart';
import '../common/tab_navigation_widget.dart';

class VentesJourModal extends StatefulWidget {
  const VentesJourModal({super.key});

  @override
  State<VentesJourModal> createState() => _VentesJourModalState();
}

class _VentesJourModalState extends State<VentesJourModal> with TabNavigationMixin {
  List<Map<String, dynamic>> _ventesJour = [];
  bool _isLoading = true;
  double _totalJour = 0.0;

  @override
  void initState() {
    super.initState();
    _loadVentesJour();
  }

  Future<void> _loadVentesJour() async {
    setState(() => _isLoading = true);
    try {
      final db = DatabaseService().database;
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final result = await db.customSelect('''
        SELECT 
          v.numventes,
          v.nfact,
          v.clt,
          v.daty,
          v.totalttc,
          v.commerc,
          v.modepai,
          v.verification
        FROM ventes v
        WHERE v.daty >= ? AND v.daty < ? AND (v.contre IS NULL OR v.contre = 0)
        ORDER BY v.daty DESC
      ''', variables: [
        Variable.withDateTime(startOfDay),
        Variable.withDateTime(endOfDay),
      ]).get();

      final ventes = result
          .map((row) => {
                'numventes': row.readNullable<String>('numventes'),
                'nfact': row.readNullable<String>('nfact'),
                'client': row.readNullable<String>('clt'),
                'date': row.readNullable<String>('daty'),
                'total': row.readNullable<double>('totalttc') ?? 0.0,
                'commerc': row.readNullable<String>('commerc'),
                'modepai': row.readNullable<String>('modepai'),
                'verification': row.readNullable<String>('verification'),
              })
          .toList();

      final total = ventes.fold<double>(0.0, (sum, vente) => sum + (vente['total'] as double));

      setState(() {
        _ventesJour = ventes;
        _totalJour = total;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
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
          width: 1000,
          height: 750,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header moderne
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue[600]!, Colors.blue[700]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.today,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ventes du Jour',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            _formatDate(DateTime.now()),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _loadVentesJour,
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      tooltip: 'Actualiser',
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                      tooltip: 'Fermer',
                    ),
                  ],
                ),
              ),

              // Statistiques en cartes
              Container(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Nombre de ventes',
                        _ventesJour.length.toString(),
                        Icons.receipt_long,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        'Chiffre d\'affaires',
                        '${_formatNumber(_totalJour)} Ar',
                        Icons.monetization_on,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        'Panier moyen',
                        _ventesJour.isNotEmpty
                            ? '${_formatNumber(_totalJour / _ventesJour.length)} Ar'
                            : '0 Ar',
                        Icons.shopping_cart,
                        Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),

              // Liste des ventes avec design moderne
              Expanded(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: _isLoading
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Chargement des ventes...'),
                            ],
                          ),
                        )
                      : _ventesJour.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.inbox_outlined,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Aucune vente aujourd\'hui',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Les ventes apparaîtront ici une fois effectuées',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Column(
                              children: [
                                // En-tête du tableau
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(12),
                                      topRight: Radius.circular(12),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      _buildHeaderCell('N° Vente', flex: 2),
                                      _buildHeaderCell('Client', flex: 3),
                                      _buildHeaderCell('Heure', flex: 2),
                                      _buildHeaderCell('Montant', flex: 2),
                                      _buildHeaderCell('Mode', flex: 2),
                                      _buildHeaderCell('Commercial', flex: 2),
                                      _buildHeaderCell('Statut', flex: 2),
                                    ],
                                  ),
                                ),
                                // Corps du tableau
                                Expanded(
                                  child: ListView.builder(
                                    itemCount: _ventesJour.length,
                                    itemBuilder: (context, index) {
                                      final vente = _ventesJour[index];
                                      return _buildVenteRow(vente, index);
                                    },
                                  ),
                                ),
                              ],
                            ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'JOURNAL':
        return Colors.green;
      case 'BROUILLARD':
        return Colors.orange;
      case 'CONTRE_PASSE':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatNumber(double number) {
    return number.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',
        );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildVenteRow(Map<String, dynamic> vente, int index) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: index.isEven ? Colors.white : Colors.grey[50],
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vente['numventes']?.toString() ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                if (vente['nfact']?.toString().isNotEmpty == true)
                  Text(
                    'F: ${vente['nfact']}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              vente['client']?.toString() ?? 'Client',
              style: const TextStyle(fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _formatTime(vente['date']),
              style: const TextStyle(fontSize: 13),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${_formatNumber(vente['total'])} Ar',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _getModeColor(vente['modepai']).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                vente['modepai']?.toString() ?? '',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: _getModeColor(vente['modepai']),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              vente['commerc']?.toString() ?? '',
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(vente['verification']).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                vente['verification']?.toString() ?? 'BROUILLARD',
                style: TextStyle(
                  color: _getStatusColor(vente['verification']),
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getModeColor(String? mode) {
    switch (mode) {
      case 'Espèces':
        return Colors.green;
      case 'A crédit':
        return Colors.orange;
      case 'Chèque':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatTime(dynamic dateValue) {
    if (dateValue == null) return '';

    DateTime date;
    if (dateValue is String) {
      try {
        date = DateTime.parse(dateValue);
      } catch (e) {
        return '';
      }
    } else if (dateValue is DateTime) {
      date = dateValue;
    } else {
      return '';
    }

    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
