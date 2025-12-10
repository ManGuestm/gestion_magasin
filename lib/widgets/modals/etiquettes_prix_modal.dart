import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../database/database.dart';
import '../common/tab_navigation_widget.dart';

class EtiquettesPrixModal extends StatefulWidget {
  const EtiquettesPrixModal({super.key});

  @override
  State<EtiquettesPrixModal> createState() => _EtiquettesPrixModalState();
}

class _EtiquettesPrixModalState extends State<EtiquettesPrixModal> with TabNavigationMixin {
  List<Article> _articles = [];
  List<Article> _filteredArticles = [];
  bool _isLoading = false;
  final GlobalKey _printKey = GlobalKey();
  final List<Article> _selectedArticles = [];
  bool _selectMode = false;
  final TextEditingController _searchController = TextEditingController();
  String _paperFormat = 'A4';
  int _labelsPerPage = 12;

  @override
  void initState() {
    super.initState();
    _loadArticles();
  }

  Future<void> _loadArticles() async {
    setState(() => _isLoading = true);
    try {
      final db = AppDatabase();
      final articles = await db.getActiveArticles();
      setState(() {
        _articles = articles;
        _filteredArticles = articles;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _filterArticles(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredArticles = _articles;
      } else {
        _filteredArticles = _articles.where((article) {
          return article.designation.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  String _formatPriceForLabel(double price) {
    return NumberFormat('#,###', 'fr_FR').format(price.round());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.grey[50]!, Colors.white],
          ),
        ),
        child: Column(
          children: [_buildModernHeader(), _buildToolbar(), _buildPriceLabelsGrid(), _buildModernFooter()],
        ),
      ),
    );
  }

  Widget _buildModernHeader() {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.blue[600]!, Colors.blue[800]!]),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.local_offer, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          const Text(
            'Étiquettes de Prix Professionnelles',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Colors.white, size: 24),
            tooltip: 'Fermer',
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Column(
      children: [
        Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _searchController,
                  onChanged: _filterArticles,
                  decoration: InputDecoration(
                    hintText: 'Rechercher un article...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _filterArticles('');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => setState(() => _selectMode = !_selectMode),
                icon: Icon(_selectMode ? Icons.check_circle : Icons.radio_button_unchecked),
                label: Text(_selectMode ? 'Sélection' : 'Sélectionner'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectMode ? Colors.green : Colors.grey[600],
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _showPrintSettings,
                icon: const Icon(Icons.settings),
                label: const Text('Format'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[600],
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        if (_selectMode)
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                Text(
                  '${_selectedArticles.length} sélectionnés',
                  style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: () => setState(() => _selectedArticles.clear()),
                  child: const Text('Tout désélectionner'),
                ),
                const Spacer(),
                Text(
                  '${_filteredArticles.length} articles affichés',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildPriceLabelsGrid() {
    return Expanded(
      child: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Chargement des articles...'),
                ],
              ),
            )
          : RepaintBoundary(
              key: _printKey,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    childAspectRatio: 1.2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _filteredArticles.length,
                  itemBuilder: (context, index) {
                    final article = _filteredArticles[index];
                    return _buildPriceLabel(article);
                  },
                ),
              ),
            ),
    );
  }

  Widget _buildPriceLabel(Article article) {
    final isSelected = _selectedArticles.contains(article);

    return GestureDetector(
      onTap: _selectMode
          ? () {
              setState(() {
                if (isSelected) {
                  _selectedArticles.remove(article);
                } else {
                  _selectedArticles.add(article);
                }
              });
            }
          : null,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: isSelected ? Colors.blue : Colors.black, width: 2),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 2, offset: const Offset(1, 1)),
          ],
        ),
        child: Column(
          children: [
            // Header avec nom du produit
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Colors.black, width: 2)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      article.designation,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (_selectMode)
                    Icon(
                      isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                      size: 20,
                      color: isSelected ? Colors.green : Colors.grey,
                    ),
                ],
              ),
            ),
            // Headers des colonnes
            SizedBox(
              height: 30,
              child: Row(
                children: [
                  Container(
                    width: 60,
                    decoration: const BoxDecoration(
                      border: Border(right: BorderSide(color: Colors.black, width: 1)),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        border: Border(right: BorderSide(color: Colors.black, width: 1)),
                      ),
                      child: const Center(
                        child: Text(
                          'En Ariary',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'En Fmg',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Corps avec prix
            Expanded(
              child: Column(
                children: [
                  if (article.u1 != null && article.pvu1 != null)
                    _buildPriceRow(article.u1!, article.pvu1!, (article.pvu1! * 5)),
                  if (article.u2 != null && article.pvu2 != null)
                    _buildPriceRow(article.u2!, article.pvu2!, (article.pvu2! * 5)),
                  if (article.u3 != null && article.pvu3 != null)
                    _buildPriceRow(article.u3!, article.pvu3!, (article.pvu3! * 5)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String unit, double ariaryPrice, double fmgPrice) {
    return Expanded(
      child: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Colors.black, width: 1)),
        ),
        child: Row(
          children: [
            // Unité
            Container(
              width: 60,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: const BoxDecoration(
                border: Border(right: BorderSide(color: Colors.black, width: 1)),
              ),
              child: Text(
                unit,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                textAlign: TextAlign.center,
              ),
            ),
            // Prix Ariary
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: const BoxDecoration(
                  border: Border(right: BorderSide(color: Colors.black, width: 1)),
                ),
                child: Text(
                  _formatPriceForLabel(ariaryPrice),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            // Prix Fmg
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  _formatPriceForLabel(fmgPrice),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernFooter() {
    return Container(
      height: 70,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, -2)),
        ],
      ),
      child: Row(
        children: [
          if (_selectMode && _selectedArticles.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Text(
                '${_selectedArticles.length} étiquette(s) sélectionnée(s)',
                style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.w500),
              ),
            ),
          ],
          const Spacer(),
          ElevatedButton.icon(
            onPressed: _printLabels,
            icon: const Icon(Icons.print),
            label: Text(_selectMode && _selectedArticles.isNotEmpty ? 'Imprimer Sélection' : 'Imprimer Tout'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
            label: const Text('Fermer'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _printLabels() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Préparation de l\'impression...'),
            ],
          ),
        ),
      );

      RenderRepaintBoundary boundary = _printKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final tempDir = Directory.systemTemp;
      final fileName = 'etiquettes_prix_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${tempDir.path}\\$fileName');
      await file.writeAsBytes(pngBytes);

      if (mounted) Navigator.of(context).pop();

      // Méthode 1: Utiliser rundll32 pour imprimer directement
      final result1 = await Process.run('rundll32', ['shimgvw.dll,ImageView_PrintTo', file.path]);

      if (result1.exitCode != 0) {
        // Méthode 2: Utiliser mspaint comme fallback
        final result2 = await Process.run('mspaint', ['/p', file.path]);

        if (result2.exitCode != 0) {
          // Méthode 3: Ouvrir avec l'application par défaut
          await Process.run('cmd', ['/c', 'start', '', file.path]);
          _showSuccessMessage('Image ouverte. Utilisez Ctrl+P pour imprimer.');
        } else {
          _showSuccessMessage('Impression lancée avec Paint!');
        }
      } else {
        _showSuccessMessage('Impression lancée avec succès!');
      }

      // Nettoyer après 30 secondes
      Future.delayed(const Duration(seconds: 30), () {
        if (file.existsSync()) {
          file.deleteSync();
        }
      });
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      _showErrorMessage('Erreur lors de l\'impression: $e');
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void _showPrintSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Paramètres d\'impression'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _paperFormat,
              decoration: const InputDecoration(labelText: 'Format de papier', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'A4', child: Text('A4 (210 × 297 mm)')),
                DropdownMenuItem(value: 'A5', child: Text('A5 (148 × 210 mm)')),
                DropdownMenuItem(value: 'A6', child: Text('A6 (105 × 148 mm)')),
              ],
              onChanged: (value) => setState(() => _paperFormat = value!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _labelsPerPage.toString(),
              decoration: const InputDecoration(
                labelText: 'Étiquettes par page',
                border: OutlineInputBorder(),
                helperText: 'Nombre d\'étiquettes à imprimer par page',
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                final parsed = int.tryParse(value);
                if (parsed != null && parsed > 0) {
                  setState(() => _labelsPerPage = parsed);
                }
              },
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Format sélectionné: $_paperFormat',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('Étiquettes par page: $_labelsPerPage'),
                  const SizedBox(height: 8),
                  Text(
                    'Recommandations:',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[700]),
                  ),
                  const Text('• A4: 12-16 étiquettes'),
                  const Text('• A5: 6-8 étiquettes'),
                  const Text('• A6: 2-4 étiquettes'),
                ],
              ),
            ),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Fermer'))],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
