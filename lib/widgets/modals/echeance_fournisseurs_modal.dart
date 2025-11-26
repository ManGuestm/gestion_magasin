import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../constants/app_functions.dart';
import '../../database/database.dart';
import '../../screens/echeances_fournisseurs_preview_screen.dart';
import '../common/tab_navigation_widget.dart';

class EchanceFournisseursModal extends StatefulWidget {
  const EchanceFournisseursModal({super.key});

  @override
  State<EchanceFournisseursModal> createState() => _EchanceFournisseursModalState();
}

class _EchanceFournisseursModalState extends State<EchanceFournisseursModal> with TabNavigationMixin {
  List<Achat> _achats = [];
  List<Achat> _filteredAchats = [];
  String? _selectedFournisseur;
  String _numAchatsFilter = '';
  String? _selectedStatut;
  DateTime? _dateEcheanceDebut;
  DateTime? _dateEcheanceFin;
  bool _isLoading = false;
  int _selectedIndex = -1;
  int _currentPage = 0;
  final int _itemsPerPage = 20;
  final TextEditingController _numAchatsController = TextEditingController();
  final TextEditingController _dateDebutController = TextEditingController();
  final TextEditingController _dateFinController = TextEditingController();

  List<Achat> get _paginatedAchats {
    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, _filteredAchats.length);
    return _filteredAchats.sublist(startIndex, endIndex);
  }

  int get _totalPages => (_filteredAchats.length / _itemsPerPage).ceil();

  @override
  void initState() {
    super.initState();
    _loadAchats();
    _numAchatsController.addListener(() {
      setState(() {
        _numAchatsFilter = _numAchatsController.text;
      });
      _filterAchats();
    });
  }

  @override
  void dispose() {
    _numAchatsController.dispose();
    _dateDebutController.dispose();
    _dateFinController.dispose();
    super.dispose();
  }

  Future<void> _loadAchats() async {
    setState(() => _isLoading = true);
    try {
      final db = AppDatabase();
      final achats = await db.getAllAchats();
      setState(() {
        _achats = achats.where((a) => (a.regl ?? 0) < (a.totalttc ?? 0)).toList();
        _filteredAchats = _achats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void refreshData() {
    _loadAchats();
  }

  void _filterAchats() {
    setState(() {
      _filteredAchats = _achats.where((a) {
        bool matchesFournisseur = _selectedFournisseur == null || a.frns == _selectedFournisseur;
        bool matchesNumAchats = _numAchatsFilter.isEmpty ||
            (a.numachats ?? '').toLowerCase().contains(_numAchatsFilter.toLowerCase());

        // Filtre par statut
        bool matchesStatut = true;
        if (_selectedStatut != null) {
          final isOverdue = a.echeance != null && a.echeance!.isBefore(DateTime.now());
          switch (_selectedStatut) {
            case 'overdue':
              matchesStatut = isOverdue;
              break;
            case 'current':
              matchesStatut = !isOverdue;
              break;
            case 'all':
            default:
              matchesStatut = true;
          }
        }

        // Filtre par date d'échéance
        bool matchesDateRange = true;
        if (a.echeance != null) {
          if (_dateEcheanceDebut != null && a.echeance!.isBefore(_dateEcheanceDebut!)) {
            matchesDateRange = false;
          }
          if (_dateEcheanceFin != null &&
              a.echeance!.isAfter(_dateEcheanceFin!.add(const Duration(days: 1)))) {
            matchesDateRange = false;
          }
        } else if (_dateEcheanceDebut != null || _dateEcheanceFin != null) {
          matchesDateRange = false;
        }

        return matchesFournisseur && matchesNumAchats && matchesStatut && matchesDateRange;
      }).toList();
      _currentPage = 0;
      _selectedIndex = -1;
    });
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('dd/MM/yyyy').format(date);
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
          height: 700,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildHeader(),
              _buildFilters(),
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
      padding: const EdgeInsets.all(20),
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
            child: const Icon(Icons.schedule, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          const Text(
            'Échéances Fournisseurs',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close, color: Colors.white, size: 20),
              tooltip: 'Fermer',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable() {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildTableHeader(),
            Expanded(
              child: _isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Colors.blue[600]),
                          const SizedBox(height: 16),
                          Text(
                            'Chargement des échéances...',
                            style: TextStyle(color: Colors.grey[600], fontSize: 14),
                          ),
                        ],
                      ),
                    )
                  : _filteredAchats.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                'Aucune échéance trouvée',
                                style: TextStyle(color: Colors.grey[600], fontSize: 16),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _paginatedAchats.length,
                          itemExtent: 48,
                          itemBuilder: (context, index) {
                            final achat = _paginatedAchats[index];
                            final globalIndex = _currentPage * _itemsPerPage + index;
                            return _buildTableRow(achat, globalIndex);
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
      height: 50,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey[50]!, Colors.grey[100]!],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(flex: 3, child: _buildHeaderCell('Fournisseur')),
          Expanded(flex: 2, child: _buildHeaderCell('N° Facture/BL')),
          Expanded(flex: 2, child: _buildHeaderCell('N° Achat')),
          Expanded(flex: 2, child: _buildHeaderCell('Montant')),
          Expanded(flex: 2, child: _buildHeaderCell('Payé')),
          Expanded(flex: 2, child: _buildHeaderCell('Reste à payer')),
          Expanded(flex: 2, child: _buildHeaderCell('Date facture')),
          Expanded(flex: 2, child: _buildHeaderCell('Échéance')),
          Expanded(flex: 2, child: _buildHeaderCell('Statut')),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.grey[700],
          letterSpacing: 0.3,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTableRow(Achat achat, int index) {
    final isSelected = index == _selectedIndex;
    final isOverdue = achat.echeance != null && achat.echeance!.isBefore(DateTime.now());
    final resteAPayer = (achat.totalttc ?? 0) - (achat.regl ?? 0);

    Color? bgColor;
    if (isSelected) {
      bgColor = Colors.blue[100];
    } else if (isOverdue) {
      bgColor = Colors.red[50];
    } else {
      bgColor = index % 2 == 0 ? Colors.white : Colors.grey[25];
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: bgColor,
          border: Border(
            bottom: BorderSide(color: Colors.grey[200]!, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            Expanded(flex: 3, child: _buildCell(achat.frns ?? '')),
            Expanded(flex: 2, child: _buildCell(achat.nfact ?? '')),
            Expanded(flex: 2, child: _buildCell(achat.numachats ?? '')),
            Expanded(
                flex: 2,
                child: _buildCell(AppFunctions.formatNumber(achat.totalttc ?? 0),
                    alignment: Alignment.centerRight)),
            Expanded(
                flex: 2,
                child:
                    _buildCell(AppFunctions.formatNumber(achat.regl ?? 0), alignment: Alignment.centerRight)),
            Expanded(
                flex: 2,
                child: _buildCell(AppFunctions.formatNumber(resteAPayer),
                    alignment: Alignment.centerRight,
                    color: resteAPayer > 0 ? Colors.orange[700] : Colors.green[700])),
            Expanded(flex: 2, child: _buildCell(_formatDate(achat.daty))),
            Expanded(
                flex: 2,
                child: _buildCell(_formatDate(achat.echeance), color: isOverdue ? Colors.red[700] : null)),
            Expanded(flex: 2, child: _buildStatusCell(isOverdue)),
          ],
        ),
      ),
    );
  }

  Widget _buildCell(String text, {Alignment alignment = Alignment.centerLeft, Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      alignment: alignment,
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: color ?? Colors.grey[800],
          fontWeight: color != null ? FontWeight.w500 : FontWeight.normal,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildStatusCell(bool isOverdue) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      alignment: Alignment.center,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isOverdue ? Colors.red[100] : Colors.green[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isOverdue ? Colors.red[300]! : Colors.green[300]!,
            width: 1,
          ),
        ),
        child: Text(
          isOverdue ? 'En retard' : 'À jour',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: isOverdue ? Colors.red[700] : Colors.green[700],
          ),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildFilterField(
                  'N° Achat',
                  _numAchatsController,
                  Icons.receipt_outlined,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildFournisseurFilter(),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatutFilter(),
              ),
              const SizedBox(width: 16),
              _buildClearFiltersButton(),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDateFilter(
                  'Date échéance (début)',
                  _dateDebutController,
                  (date) {
                    setState(() {
                      _dateEcheanceDebut = date;
                      if (date != null) {
                        _dateDebutController.text = _formatDate(date);
                      } else {
                        _dateDebutController.clear();
                      }
                    });
                    _filterAchats();
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDateFilter(
                  'Date échéance (fin)',
                  _dateFinController,
                  (date) {
                    setState(() {
                      _dateEcheanceFin = date;
                      if (date != null) {
                        _dateFinController.text = _formatDate(date);
                      } else {
                        _dateFinController.clear();
                      }
                    });
                    _filterAchats();
                  },
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(child: SizedBox()),
              const SizedBox(width: 16),
              const SizedBox(width: 100),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterField(String label, TextEditingController controller, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: TextField(
            controller: controller,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              prefixIcon: Icon(icon, size: 18, color: Colors.grey[500]),
              hintText: 'Rechercher...',
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFournisseurFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fournisseur',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButtonFormField<String>(
            initialValue: _selectedFournisseur,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              prefixIcon: Icon(Icons.business_outlined, size: 18),
            ),
            style: const TextStyle(fontSize: 14, color: Colors.black),
            items: [
              const DropdownMenuItem(value: null, child: Text('Tous les fournisseurs')),
              ..._achats.map((a) => a.frns).toSet().map((frns) => DropdownMenuItem(
                    value: frns,
                    child: Text(frns ?? '', style: const TextStyle(fontSize: 14)),
                  )),
            ],
            onChanged: (value) {
              setState(() {
                _selectedFournisseur = value;
              });
              _filterAchats();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildClearFiltersButton() {
    return Column(
      children: [
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: _showAll,
          icon: const Icon(Icons.clear_all, size: 16),
          label: const Text('Effacer'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[100],
            foregroundColor: Colors.grey[700],
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: Colors.grey[300]!),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        border: Border(
          top: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
      ),
      child: Row(
        children: [
          _buildNavigationButtons(),
          const Spacer(),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      children: [
        Text(
          '${_filteredAchats.length} échéance${_filteredAchats.length > 1 ? 's' : ''} trouvée${_filteredAchats.length > 1 ? 's' : ''}',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 16),
        if (_totalPages > 1) ...[
          _buildNavButton(Icons.first_page, _currentPage > 0 ? () => _goToPage(0) : null),
          _buildNavButton(Icons.chevron_left, _currentPage > 0 ? () => _goToPage(_currentPage - 1) : null),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Text(
              '${_currentPage + 1} / $_totalPages',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.blue[700],
              ),
            ),
          ),
          _buildNavButton(
              Icons.chevron_right, _currentPage < _totalPages - 1 ? () => _goToPage(_currentPage + 1) : null),
          _buildNavButton(
              Icons.last_page, _currentPage < _totalPages - 1 ? () => _goToPage(_totalPages - 1) : null),
        ],
      ],
    );
  }

  void _goToPage(int page) {
    setState(() {
      _currentPage = page;
      _selectedIndex = -1;
    });
  }

  Widget _buildNavButton(IconData icon, VoidCallback? onPressed) {
    return Container(
      width: 32,
      height: 32,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: onPressed != null ? Colors.white : Colors.grey[100],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: onPressed != null
            ? [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ]
            : null,
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          size: 16,
          color: onPressed != null ? Colors.grey[700] : Colors.grey[400],
        ),
        padding: EdgeInsets.zero,
        tooltip: _getNavButtonTooltip(icon),
      ),
    );
  }

  String _getNavButtonTooltip(IconData icon) {
    switch (icon) {
      case Icons.first_page:
        return 'Première page';
      case Icons.chevron_left:
        return 'Page précédente';
      case Icons.chevron_right:
        return 'Page suivante';
      case Icons.last_page:
        return 'Dernière page';
      default:
        return '';
    }
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        ElevatedButton.icon(
          onPressed: _printDirect,
          icon: const Icon(Icons.print, size: 16),
          label: const Text('Imprimer'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[600],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 2,
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: _showPrintPreview,
          icon: const Icon(Icons.preview, size: 16),
          label: const Text('Aperçu'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[600],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 2,
          ),
        ),
        const SizedBox(width: 12),
        OutlinedButton.icon(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close, size: 16),
          label: const Text('Fermer'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.grey[700],
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            side: BorderSide(color: Colors.grey[300]!),
          ),
        ),
      ],
    );
  }

  void _showAll() {
    setState(() {
      _selectedFournisseur = null;
      _selectedStatut = null;
      _dateEcheanceDebut = null;
      _dateEcheanceFin = null;
      _numAchatsController.clear();
      _dateDebutController.clear();
      _dateFinController.clear();
      _numAchatsFilter = '';
    });
    _filterAchats();
  }

  Widget _buildStatutFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Statut',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButtonFormField<String>(
            initialValue: _selectedStatut,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              prefixIcon: Icon(Icons.flag_outlined, size: 18),
            ),
            style: const TextStyle(fontSize: 14, color: Colors.black),
            items: const [
              DropdownMenuItem(value: null, child: Text('Tous les statuts')),
              DropdownMenuItem(value: 'current', child: Text('À jour')),
              DropdownMenuItem(value: 'overdue', child: Text('En retard')),
            ],
            onChanged: (value) {
              setState(() {
                _selectedStatut = value;
              });
              _filterAchats();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDateFilter(
      String label, TextEditingController controller, Function(DateTime?) onDateSelected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: TextField(
            controller: controller,
            readOnly: true,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              prefixIcon: Icon(Icons.calendar_today_outlined, size: 18, color: Colors.grey[500]),
              suffixIcon: controller.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, size: 16, color: Colors.grey[500]),
                      onPressed: () {
                        controller.clear();
                        onDateSelected(null);
                      },
                    )
                  : null,
              hintText: 'Sélectionner date...',
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
                locale: const Locale('fr', 'FR'),
              );
              if (date != null) {
                onDateSelected(date);
              }
            },
          ),
        ),
      ],
    );
  }

  Future<void> _printDirect() async {
    if (_filteredAchats.isEmpty) {
      _showMessage('Aucune donnée à imprimer', Colors.orange[600]!);
      return;
    }

    try {
      final printers = await Printing.listPrinters();
      final defaultPrinter = printers.firstWhere(
        (printer) => printer.isDefault,
        orElse: () => printers.isNotEmpty ? printers.first : throw Exception('Aucune imprimante'),
      );

      await Printing.directPrintPdf(
        printer: defaultPrinter,
        onLayout: _generatePdf,
        usePrinterSettings: true,
      );
      _showMessage('Impression lancée vers ${defaultPrinter.name}', Colors.green[600]!);
    } catch (e) {
      _showMessage('Erreur lors de l\'impression: $e', Colors.red[600]!);
    }
  }

  void _showPrintPreview() {
    if (_filteredAchats.isEmpty) {
      _showMessage('Aucune donnée à afficher', Colors.orange[600]!);
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EchancesFournisseursPreviewScreen(
          achats: _filteredAchats,
          selectedFournisseur: _selectedFournisseur,
          selectedStatut: _selectedStatut,
          dateDebut: _dateEcheanceDebut,
          dateFin: _dateEcheanceFin,
        ),
      ),
    );
  }

  Future<Uint8List> _generatePdf(PdfPageFormat format) async {
    final pdf = pw.Document();
    final itemsPerPage = 25;
    final totalPages = (_filteredAchats.length / itemsPerPage).ceil();

    for (int pageIndex = 0; pageIndex < totalPages; pageIndex++) {
      final startIndex = pageIndex * itemsPerPage;
      final endIndex = (startIndex + itemsPerPage).clamp(0, _filteredAchats.length);
      final pageAchats = _filteredAchats.sublist(startIndex, endIndex);

      pdf.addPage(
        pw.Page(
          pageFormat: format,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildPdfHeader(),
                pw.SizedBox(height: 20),
                _buildPdfTable(pageAchats),
                pw.Spacer(),
                _buildPdfFooter(pageIndex + 1, totalPages),
              ],
            );
          },
        ),
      );
    }

    return pdf.save();
  }

  pw.Widget _buildPdfHeader() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'LISTE DES FACTURES À PAYER',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        if (_selectedFournisseur != null) pw.Text('Fournisseur: $_selectedFournisseur'),
        if (_selectedStatut != null) pw.Text('Statut: ${_getStatutLabel(_selectedStatut!)}'),
        if (_dateEcheanceDebut != null || _dateEcheanceFin != null)
          pw.Text('Période: ${_formatDate(_dateEcheanceDebut)} - ${_formatDate(_dateEcheanceFin)}'),
        pw.Text('Total: ${_filteredAchats.length} échéance${_filteredAchats.length > 1 ? 's' : ''}'),
        pw.Text('Date d\'impression: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}'),
      ],
    );
  }

  pw.Widget _buildPdfTable(List<Achat> achats) {
    return pw.Table(
      border: pw.TableBorder.all(),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FlexColumnWidth(2),
        4: const pw.FlexColumnWidth(2),
        5: const pw.FlexColumnWidth(2),
        6: const pw.FlexColumnWidth(2),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            _buildPdfHeaderCell('FOURNISSEURS'),
            _buildPdfHeaderCell('N°BL/F'),
            _buildPdfHeaderCell('MONTANT'),
            _buildPdfHeaderCell('PAYÉ'),
            _buildPdfHeaderCell('RESTE À PAYER'),
            _buildPdfHeaderCell('DATE FACTURE'),
            _buildPdfHeaderCell('ÉCHÉANCE'),
          ],
        ),
        ...achats.map((achat) {
          final resteAPayer = (achat.totalttc ?? 0) - (achat.regl ?? 0);
          return pw.TableRow(
            children: [
              _buildPdfCell(achat.frns ?? ''),
              _buildPdfCell(achat.nfact ?? ''),
              _buildPdfCell(AppFunctions.formatNumber(achat.totalttc ?? 0)),
              _buildPdfCell(AppFunctions.formatNumber(achat.regl ?? 0)),
              _buildPdfCell(AppFunctions.formatNumber(resteAPayer)),
              _buildPdfCell(_formatDate(achat.daty)),
              _buildPdfCell(_formatDate(achat.echeance)),
            ],
          );
        }),
      ],
    );
  }

  pw.Widget _buildPdfHeaderCell(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  pw.Widget _buildPdfCell(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 9),
      ),
    );
  }

  pw.Widget _buildPdfFooter(int currentPage, int totalPages) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text('GESTION COMMERCIALE DES PME'),
        pw.Text(DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now())),
        pw.Text('$currentPage'),
      ],
    );
  }

  String _getStatutLabel(String statut) {
    switch (statut) {
      case 'current':
        return 'À jour';
      case 'overdue':
        return 'En retard';
      default:
        return 'Tous';
    }
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
