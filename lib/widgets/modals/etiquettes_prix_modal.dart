import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../database/database.dart';

class EtiquettesPrixModal extends StatefulWidget {
  const EtiquettesPrixModal({super.key});

  @override
  State<EtiquettesPrixModal> createState() => _EtiquettesPrixModalState();
}

class _EtiquettesPrixModalState extends State<EtiquettesPrixModal> {
  List<Article> _articles = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadArticles();
  }

  Future<void> _loadArticles() async {
    setState(() => _isLoading = true);
    try {
      final db = AppDatabase();
      final articles = await db.getAllArticles();
      setState(() {
        _articles = articles;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
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
        width: 800,
        height: 600,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black, width: 2),
          color: Colors.grey[200],
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
      height: 25,
      decoration: BoxDecoration(
        color: Colors.blue[400],
        border: Border.all(color: Colors.black, width: 1),
      ),
      child: Row(
        children: [
          const SizedBox(width: 8),
          const Icon(Icons.label, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          const Text(
            'ETIQUETTES DE PRIX',
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
                      itemCount: _articles.length,
                      itemExtent: 16,
                      itemBuilder: (context, index) {
                        final article = _articles[index];
                        return _buildTableRow(article, index);
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
          _buildHeaderCell('DESIGNATION', 200),
          _buildHeaderCell('PRIX U1', 80),
          _buildHeaderCell('PRIX U2', 80),
          _buildHeaderCell('PRIX U3', 80),
          _buildHeaderCell('U1', 60),
          _buildHeaderCell('U2', 60),
          _buildHeaderCell('U3', 60),
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

  Widget _buildTableRow(Article article, int index) {
    final bgColor = index % 2 == 0 ? Colors.white : Colors.grey[100];

    return Container(
      height: 16,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: Colors.black, width: 0.5),
      ),
      child: Row(
        children: [
          _buildCell(article.designation, 200),
          _buildCell(_formatNumber(article.pvu1), 80, alignment: Alignment.centerRight),
          _buildCell(_formatNumber(article.pvu2), 80, alignment: Alignment.centerRight),
          _buildCell(_formatNumber(article.pvu3), 80, alignment: Alignment.centerRight),
          _buildCell(article.u1 ?? '', 60),
          _buildCell(article.u2 ?? '', 60),
          _buildCell(article.u3 ?? '', 60),
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