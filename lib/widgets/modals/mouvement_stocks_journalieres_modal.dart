import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../database/database.dart';

class MouvementStocksJournalieresModal extends StatefulWidget {
  const MouvementStocksJournalieresModal({super.key});

  @override
  State<MouvementStocksJournalieresModal> createState() => _MouvementStocksJournalieresModalState();
}

class _MouvementStocksJournalieresModalState extends State<MouvementStocksJournalieresModal> {
  List<Stock> _mouvements = [];
  bool _isLoading = false;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadMouvements();
  }

  Future<void> _loadMouvements() async {
    setState(() => _isLoading = true);
    try {
      final db = AppDatabase();
      final mouvements = await db.getAllStocks();
      setState(() {
        _mouvements = mouvements.where((m) => 
          m.daty != null && 
          DateFormat('yyyy-MM-dd').format(m.daty!) == DateFormat('yyyy-MM-dd').format(_selectedDate)
        ).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
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
      backgroundColor: Colors.transparent,
      child: Container(
        width: 1200,
        height: 600,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black, width: 2),
          color: Colors.grey[200],
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
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      height: 25,
      decoration: BoxDecoration(
        color: Colors.blue[400],
        border: Border.all(color: Colors.black, width: 1),
      ),
      child: Row(
        children: [
          const SizedBox(width: 8),
          const Icon(Icons.timeline, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          const Text(
            'MOUVEMENT DE STOCKS JOURNALIERES',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const Spacer(),
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.red,
              border: Border.all(color: Colors.white, width: 1),
            ),
            child: InkWell(
              onTap: () => Navigator.of(context).pop(),
              child: const Icon(Icons.close, size: 10, color: Colors.white),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      height: 30,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        border: Border.all(color: Colors.black, width: 1),
      ),
      child: Row(
        children: [
          const Text('Date:', style: TextStyle(fontSize: 10)),
          const SizedBox(width: 8),
          Container(
            width: 100,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black, width: 1),
            ),
            child: InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (date != null) {
                  setState(() {
                    _selectedDate = date;
                  });
                  _loadMouvements();
                }
              },
              child: Center(
                child: Text(
                  _formatDate(_selectedDate),
                  style: const TextStyle(fontSize: 9),
                ),
              ),
            ),
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
                      itemCount: _mouvements.length,
                      itemExtent: 16,
                      itemBuilder: (context, index) {
                        final mouvement = _mouvements[index];
                        return _buildTableRow(mouvement, index);
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
      height: 20,
      decoration: BoxDecoration(
        color: Colors.orange[300],
        border: Border.all(color: Colors.black, width: 1),
      ),
      child: Row(
        children: [
          _buildHeaderCell('DATE', 80),
          _buildHeaderCell('ARTICLE', 150),
          _buildHeaderCell('LIBELLE', 150),
          _buildHeaderCell('QTE ENTREE', 80),
          _buildHeaderCell('QTE SORTIE', 80),
          _buildHeaderCell('UNITE', 60),
          _buildHeaderCell('DEPOT', 80),
          _buildHeaderCell('N° VENTE', 80),
          _buildHeaderCell('N° ACHAT', 80),
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
          right: BorderSide(color: Colors.black, width: 1),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTableRow(Stock mouvement, int index) {
    final bgColor = index % 2 == 0 ? Colors.white : Colors.grey[100];

    return Container(
      height: 16,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: Colors.black, width: 0.5),
      ),
      child: Row(
        children: [
          _buildCell(_formatDate(mouvement.daty), 80),
          _buildCell(mouvement.refart ?? '', 150),
          _buildCell(mouvement.lib ?? '', 150),
          _buildCell(_formatNumber(mouvement.qe), 80, alignment: Alignment.centerRight),
          _buildCell(_formatNumber(mouvement.qs), 80, alignment: Alignment.centerRight),
          _buildCell(mouvement.ue ?? '', 60),
          _buildCell(mouvement.depots ?? '', 80),
          _buildCell(mouvement.numventes ?? '', 80),
          _buildCell(mouvement.numachats ?? '', 80),
        ],
      ),
    );
  }

  Widget _buildCell(String text, double width, {Alignment alignment = Alignment.centerLeft}) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 2),
      alignment: alignment,
      decoration: const BoxDecoration(
        border: Border(
          right: BorderSide(color: Colors.black, width: 0.5),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 9, color: Colors.black),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      height: 30,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        border: Border.all(color: Colors.black, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _buildActionButton('Imprimer', () {}),
          _buildActionButton('Fermer', () => Navigator.of(context).pop()),
        ],
      ),
    );
  }

  Widget _buildActionButton(String text, VoidCallback onPressed) {
    return Container(
      height: 20,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 1),
      ),
      child: InkWell(
        onTap: onPressed,
        child: Center(
          child: Text(
            text,
            style: const TextStyle(fontSize: 9, color: Colors.black),
          ),
        ),
      ),
    );
  }
}