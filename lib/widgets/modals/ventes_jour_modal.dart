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
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.9,
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

              // Actions et filtres
              Container(
                margin: const EdgeInsets.fromLTRB(24, 0, 24, 16),
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
                child: Row(
                  children: [
                    // Actions
                    ElevatedButton.icon(
                      onPressed: _ventesJour.isNotEmpty ? _showPreview : null,
                      icon: const Icon(Icons.print, size: 18),
                      label: const Text('Imprimer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _ventesJour.isNotEmpty ? _exportToExcel : null,
                      icon: const Icon(Icons.file_download, size: 18),
                      label: const Text('Exporter'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Informations de période
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.calendar_today, size: 16, color: Colors.blue[700]),
                          const SizedBox(width: 8),
                          Text(
                            'Aujourd\'hui: ${_formatDate(DateTime.now())}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
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
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
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
                                // En-tête du tableau avec bordures
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(12),
                                      topRight: Radius.circular(12),
                                    ),
                                    border: Border(
                                      bottom: BorderSide(color: Colors.grey[400]!, width: 0.5),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      _buildHeaderCell('N° Vente', flex: 2),
                                      _buildHeaderCell('Client', flex: 2),
                                      _buildHeaderCell('Heure', flex: 1),
                                      _buildHeaderCell('Montant', flex: 2),
                                      _buildHeaderCell('Mode', flex: 1),
                                      _buildHeaderCell('Commercial', flex: 2),
                                      _buildHeaderCell('Statut', flex: 1),
                                    ],
                                  ),
                                ),
                                // Corps du tableau avec bordures
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(color: Colors.grey[400]!, width: 0.5),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildVenteRow(Map<String, dynamic> vente, int index) {
    return Container(
      padding: EdgeInsets.zero,
      decoration: BoxDecoration(
        color: index.isEven ? Colors.white : Colors.grey[50],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Container(
              alignment: Alignment.center,
              height: 30,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey[400]!, width: 0.5),
                  right: BorderSide(color: Colors.grey[400]!, width: 0.5),
                ),
              ),
              child: Text(
                "${vente['numventes']?.toString() ?? ''} - Fact N°: ${vente['nfact']?.toString().isNotEmpty == true ? vente['nfact'] : ''}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              height: 30,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey[400]!, width: 0.5),
                  right: BorderSide(color: Colors.grey[400]!, width: 0.5),
                ),
              ),
              child: Text(
                vente['client']?.toString() ?? 'Client',
                style: const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              height: 30,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey[400]!, width: 0.5),
                  right: BorderSide(color: Colors.grey[400]!, width: 0.5),
                ),
              ),
              child: Text(
                _formatTime(vente['date']),
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              height: 30,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey[400]!, width: 0.5),
                  right: BorderSide(color: Colors.grey[400]!, width: 0.5),
                ),
              ),
              child: Text(
                '${_formatNumber(vente['total'])} Ar',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                  fontSize: 12,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              height: 30,
              decoration: BoxDecoration(
                color: _getModeColor(vente['modepai']).withValues(alpha: 0.1),
                border: Border(
                  bottom: BorderSide(color: Colors.grey[400]!, width: 0.5),
                  right: BorderSide(color: Colors.grey[400]!, width: 0.5),
                ),
              ),
              child: Text(
                vente['modepai']?.toString() ?? '',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: _getModeColor(vente['modepai']),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              height: 30,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey[400]!, width: 0.5),
                  right: BorderSide(color: Colors.grey[400]!, width: 0.5),
                ),
              ),
              child: Text(
                vente['commerc']?.toString() ?? '',
                style: const TextStyle(fontSize: 11),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              height: 30,
              decoration: BoxDecoration(
                color: _getStatusColor(vente['verification']).withValues(alpha: 0.1),
                border: Border(
                  bottom: BorderSide(color: Colors.grey[400]!, width: 0.5),
                ),
              ),
              child: Text(
                vente['verification']?.toString() ?? 'BROUILLARD',
                style: TextStyle(
                  color: _getStatusColor(vente['verification']),
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
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
      'Janvier',
      'Février',
      'Mars',
      'Avril',
      'Mai',
      'Juin',
      'Juillet',
      'Août',
      'Septembre',
      'Octobre',
      'Novembre',
      'Décembre'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatTime(dynamic dateValue) {
    if (dateValue == null) return '';

    try {
      DateTime date;

      if (dateValue is String) {
        // Try parsing as ISO string first
        if (dateValue.contains('T') || dateValue.contains('-')) {
          date = DateTime.parse(dateValue);
        } else {
          // Try parsing as timestamp
          final timestamp = int.tryParse(dateValue);
          if (timestamp != null) {
            date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
          } else {
            return '';
          }
        }
      } else if (dateValue is DateTime) {
        date = dateValue;
      } else if (dateValue is int) {
        // Unix timestamp
        date = DateTime.fromMillisecondsSinceEpoch(dateValue * 1000);
      } else {
        return '';
      }

      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      // If all parsing fails, return the original value as string
      return dateValue.toString();
    }
  }

  void _showPreview() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.9,
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
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[600],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.print, color: Colors.white),
                    const SizedBox(width: 8),
                    const Text(
                      'Aperçu - Ventes du Jour',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Center(
                        child: Text(
                          'RAPPORT DES VENTES DU JOUR',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          _formatDate(DateTime.now()),
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Summary
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildSummaryItem('Nombre de ventes', _ventesJour.length.toString()),
                          _buildSummaryItem('Total', '${_formatNumber(_totalJour)} Ar'),
                          _buildSummaryItem(
                              'Panier moyen',
                              _ventesJour.isNotEmpty
                                  ? '${_formatNumber(_totalJour / _ventesJour.length)} Ar'
                                  : '0 Ar'),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Détail des ventes:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Table preview (simplified)
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(8),
                                    topRight: Radius.circular(8),
                                  ),
                                ),
                                child: const Row(
                                  children: [
                                    Expanded(
                                        child:
                                            Text('N° Vente', style: TextStyle(fontWeight: FontWeight.bold))),
                                    Expanded(
                                        child: Text('Client', style: TextStyle(fontWeight: FontWeight.bold))),
                                    Expanded(
                                        child: Text('Heure', style: TextStyle(fontWeight: FontWeight.bold))),
                                    Expanded(
                                        child:
                                            Text('Montant', style: TextStyle(fontWeight: FontWeight.bold))),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: ListView.builder(
                                  itemCount: _ventesJour.length,
                                  itemBuilder: (context, index) {
                                    final vente = _ventesJour[index];
                                    return Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: index.isEven ? Colors.white : Colors.grey[50],
                                        border: Border(
                                          bottom: BorderSide(color: Colors.grey[200]!),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(child: Text(vente['numventes']?.toString() ?? '')),
                                          Expanded(child: Text(vente['client']?.toString() ?? 'Client')),
                                          Expanded(child: Text(_formatTime(vente['date']))),
                                          Expanded(child: Text('${_formatNumber(vente['total'])} Ar')),
                                        ],
                                      ),
                                    );
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
      ],
    );
  }

  void _exportToExcel() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fonctionnalité d\'export en cours de développement'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}
