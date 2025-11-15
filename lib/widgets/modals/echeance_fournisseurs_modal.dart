import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../database/database.dart';

class EchanceFournisseursModal extends StatefulWidget {
  const EchanceFournisseursModal({super.key});

  @override
  State<EchanceFournisseursModal> createState() => _EchanceFournisseursModalState();
}

class _EchanceFournisseursModalState extends State<EchanceFournisseursModal> {
  List<Achat> _achats = [];
  List<Achat> _filteredAchats = [];
  String? _selectedFournisseur;
  bool _isLoading = false;
  int _selectedIndex = -1;

  @override
  void initState() {
    super.initState();
    _loadAchats();
  }

  Future<void> _loadAchats() async {
    setState(() => _isLoading = true);
    try {
      final db = AppDatabase();
      final achats = await db.getAllAchats();
      setState(() {
        _achats = achats.where((a) => a.echeance != null && (a.regl ?? 0) < (a.totalttc ?? 0)).toList();
        _filteredAchats = _achats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _filterAchats() {
    setState(() {
      if (_selectedFournisseur == null) {
        _filteredAchats = _achats;
      } else {
        _filteredAchats = _achats.where((a) => a.frns == _selectedFournisseur).toList();
      }
    });
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  String _formatNumber(double? number) {
    if (number == null) return '0.00';
    return NumberFormat('#,##0.00', 'fr_FR').format(number);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.grey[100],
      child: Container(
        width: 1200,
        height: 600,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey, width: 1),
          color: Colors.white,
        ),
        child: Column(
          children: [
            _buildHeader(),
            _buildTable(),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.blue[300],
        border: Border.all(color: Colors.grey, width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.schedule, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          const Text(
            'ECHEANCE FOURNISSEURS',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Colors.white),
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
                      itemCount: _filteredAchats.length,
                      itemExtent: 18,
                      itemBuilder: (context, index) {
                        final achat = _filteredAchats[index];
                        return _buildTableRow(achat, index);
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
      height: 25,
      decoration: BoxDecoration(
        color: Colors.orange[200],
      ),
      child: Row(
        children: [
          _buildHeaderCell('FOURNISSEURS', 150),
          _buildHeaderCell('N° FACTURE/BL', 100),
          _buildHeaderCell('N° ACHATS', 80),
          _buildHeaderCell('MONTANT', 100),
          _buildHeaderCell('PAYER', 100),
          _buildHeaderCell('RESTE A PAYER', 100),
          _buildHeaderCell('DATE FACTURE', 100),
          _buildHeaderCell('ECHEANCE', 100),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text, double width) {
    return Container(
      width: width,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        border: Border(
          right: BorderSide(color: Colors.grey, width: 1),
          bottom: BorderSide(color: Colors.grey, width: 1),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTableRow(Achat achat, int index) {
    final isSelected = index == _selectedIndex;
    final bgColor = isSelected ? Colors.blue[200] : (index % 2 == 0 ? Colors.white : Colors.grey[50]);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: Container(
        height: 18,
        decoration: BoxDecoration(
          color: bgColor,
        ),
        child: Row(
          children: [
            _buildCell(achat.frns ?? '', 150),
            _buildCell(achat.nfact ?? '', 100),
            _buildCell(achat.numachats ?? '', 80),
            _buildCell(_formatNumber(achat.totalttc), 100, alignment: Alignment.centerRight),
            _buildCell(_formatNumber(achat.regl), 100, alignment: Alignment.centerRight),
            _buildCell(_formatNumber((achat.totalttc ?? 0) - (achat.regl ?? 0)), 100,
                alignment: Alignment.centerRight),
            _buildCell(_formatDate(achat.daty), 100),
            _buildCell(_formatDate(achat.echeance), 100),
          ],
        ),
      ),
    );
  }

  Widget _buildCell(String text, double width, {Alignment alignment = Alignment.centerLeft}) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      alignment: alignment,
      decoration: const BoxDecoration(
        border: Border(
          right: BorderSide(color: Colors.grey, width: 1),
          bottom: BorderSide(color: Colors.grey, width: 0.5),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 10),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      height: 40,
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey)),
      ),
      child: Row(
        children: [
          _buildNavigationButtons(),
          _buildFilterSection(),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _buildNavButton(Icons.first_page, () {}),
          _buildNavButton(Icons.chevron_left, () {}),
          _buildNavButton(Icons.chevron_right, () {}),
          _buildNavButton(Icons.last_page, () {}),
        ],
      ),
    );
  }

  Widget _buildNavButton(IconData icon, VoidCallback onPressed) {
    return Container(
      width: 24,
      height: 24,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        border: Border.all(color: Colors.grey[600]!),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 12),
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildFilterSection() {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            const Text('N° ACHATS', style: TextStyle(fontSize: 11)),
            const SizedBox(width: 8),
            Container(
              width: 100,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey),
              ),
            ),
            const SizedBox(width: 16),
            const Text('FOURNISSEURS', style: TextStyle(fontSize: 11)),
            const SizedBox(width: 8),
            Container(
              width: 150,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey),
              ),
              child: DropdownButtonFormField<String>(
                initialValue: _selectedFournisseur,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 10, color: Colors.black),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Tous')),
                  ..._achats.map((a) => a.frns).toSet().map((frns) => DropdownMenuItem(
                        value: frns,
                        child: Text(frns ?? '', style: const TextStyle(fontSize: 10)),
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
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _buildActionButton('Afficher tous', () => _filterAchats()),
          _buildActionButton('Aperçu', () {}),
          _buildActionButton('Fermer', () => Navigator.of(context).pop()),
        ],
      ),
    );
  }

  Widget _buildActionButton(String text, VoidCallback onPressed) {
    return Container(
      height: 24,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        border: Border.all(color: Colors.grey[600]!),
      ),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 11, color: Colors.black),
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
