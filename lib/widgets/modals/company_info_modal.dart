import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../database/database.dart';
import '../../database/database_service.dart';
import '../common/tab_navigation_widget.dart';

class CompanyInfoModal extends StatefulWidget {
  const CompanyInfoModal({super.key});

  @override
  State<CompanyInfoModal> createState() => _CompanyInfoModalState();
}

class _CompanyInfoModalState extends State<CompanyInfoModal> with TabNavigationMixin {
  SocData? _socData;
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, FocusNode> _focusNodes = {};

  @override
  void initState() {
    super.initState();
    _loadSocData();
  }

  @override
  Widget build(BuildContext context) {
    final bool isNewCompany = _socData == null;

    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) => handleTabNavigation(event),
      child: PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 750,
            height: MediaQuery.of(context).size.height * 0.9,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
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
                _buildHeader(isNewCompany),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        _buildIdentificationCard(),
                        const SizedBox(height: 20),
                        _buildContactCard(),
                        const SizedBox(height: 20),
                        _buildLogoAndTaxCard(),
                      ],
                    ),
                  ),
                ),
                _buildButtons(isNewCompany),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isNewCompany) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
        border: Border(bottom: BorderSide(color: Colors.blue[100]!)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.business, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isNewCompany ? 'Nouvelle société' : 'Informations société',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                Text(
                  isNewCompany
                      ? 'Enregistrer les informations de votre société'
                      : 'Modifier les informations existantes',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Colors.grey),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdentificationCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.badge, color: Colors.blue[600], size: 20),
                const SizedBox(width: 8),
                const Text(
                  'IDENTIFICATION',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      _buildModernField('rsoc', 'Raison sociale', Icons.business),
                      _buildModernField('activites', 'Activité', Icons.work),
                      _buildModernMultilineField('adr', 'Siège social', Icons.location_on),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    children: [
                      _buildModernField('capital', 'Capital', Icons.monetization_on),
                      _buildModernField('rcs', 'RCS', Icons.assignment),
                      _buildModernField('nif', 'N.I.F', Icons.numbers),
                      _buildModernField('stat', 'STAT', Icons.analytics),
                      _buildModernField('cif', 'CIF', Icons.receipt),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.contact_phone, color: Colors.green[600], size: 20),
                const SizedBox(width: 8),
                const Text(
                  'COORDONNÉES',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildModernField('tel', 'Téléphone fixe', Icons.phone)),
                const SizedBox(width: 16),
                Expanded(child: _buildModernField('port', 'Portable', Icons.smartphone)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildModernField('email', 'Email', Icons.email)),
                const SizedBox(width: 16),
                Expanded(child: _buildModernField('site', 'Site web', Icons.language)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoAndTaxCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.image, color: Colors.purple[600], size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'LOGO',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _selectLogo,
                    child: Container(
                      width: 140,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        border: Border.all(color: Colors.grey[300]!, width: 2, style: BorderStyle.solid),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _socData?.logo != null && _socData!.logo!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.file(
                                File(_socData!.logo!),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return _buildLogoPlaceholder();
                                },
                              ),
                            )
                          : _buildLogoPlaceholder(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calculate, color: Colors.orange[600], size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'FISCALITÉ',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildModernField('tva', 'Taux TVA (%)', Icons.percent),
                  _buildModernField('val', 'Valeur', Icons.attach_money),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_photo_alternate, color: Colors.grey[400], size: 32),
        const SizedBox(height: 4),
        Text(
          'Cliquer pour\nsélectionner',
          style: TextStyle(color: Colors.grey[500], fontSize: 11),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildButtons(bool isNewCompany) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(isNewCompany ? 'Annuler' : 'Fermer', style: TextStyle(color: Colors.grey[600])),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () async {
              await _saveSocData();
              if (mounted) Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 2,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(isNewCompany ? Icons.save : Icons.edit, size: 16),
                const SizedBox(width: 8),
                Text(isNewCompany ? 'Enregistrer' : 'Modifier'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernField(String key, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey[700]),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            height: 36,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(6),
            ),
            child: TextFormField(
              controller: _controllers[key],
              focusNode: _focusNodes[key],
              style: const TextStyle(fontSize: 13),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernMultilineField(String key, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey[700]),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            height: 72,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(6),
            ),
            child: TextFormField(
              controller: _controllers[key],
              focusNode: _focusNodes[key],
              maxLines: 3,
              style: const TextStyle(fontSize: 13),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(12),
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadSocData() async {
    final socList = await DatabaseService().database.getAllSoc();
    if (socList.isNotEmpty) {
      setState(() {
        _socData = socList.first;
      });
    }
    _initControllers();
  }

  void _initControllers() {
    final fields = [
      'rsoc',
      'activites',
      'adr',
      'tel',
      'email',
      'site',
      'capital',
      'rcs',
      'nif',
      'stat',
      'cif',
      'port',
      'tva',
      'val',
      't',
    ];

    for (String field in fields) {
      _controllers[field] ??= TextEditingController();
      _focusNodes[field] ??= FocusNode();
    }

    if (_socData != null) {
      _controllers['rsoc']!.text = _socData!.rsoc ?? '';
      _controllers['activites']!.text = _socData!.activites ?? '';
      _controllers['adr']!.text = _socData!.adr ?? '';
      _controllers['tel']!.text = _socData!.tel ?? '';
      _controllers['email']!.text = _socData!.email ?? '';
      _controllers['site']!.text = _socData!.site ?? '';
      _controllers['capital']!.text = _socData!.capital?.toString() ?? '';
      _controllers['rcs']!.text = _socData!.rcs ?? '';
      _controllers['nif']!.text = _socData!.nif ?? '';
      _controllers['stat']!.text = _socData!.stat ?? '';
      _controllers['cif']!.text = _socData!.cif ?? '';
      _controllers['port']!.text = _socData!.port ?? '';
      _controllers['tva']!.text = _socData!.tva?.toString() ?? '';
      _controllers['val']!.text = _socData!.val ?? '';
      _controllers['t']!.text = _socData!.t?.toString() ?? '';
    }
  }

  Future<void> _selectLogo() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null) {
      setState(() {
        if (_socData != null) {
          _socData = _socData!.copyWith(logo: drift.Value(result.files.single.path));
        } else {
          _socData = SocData(
            ref: 'SOC001',
            rsoc: _controllers['rsoc']?.text,
            activites: _controllers['activites']?.text,
            adr: _controllers['adr']?.text,
            logo: result.files.single.path,
            capital: double.tryParse(_controllers['capital']?.text ?? ''),
            rcs: _controllers['rcs']?.text,
            nif: _controllers['nif']?.text,
            stat: _controllers['stat']?.text,
            tel: _controllers['tel']?.text,
            port: _controllers['port']?.text,
            email: _controllers['email']?.text,
            site: _controllers['site']?.text,
            fax: null,
            telex: null,
            tva: double.tryParse(_controllers['tva']?.text ?? ''),
            t: double.tryParse(_controllers['t']?.text ?? ''),
            val: _controllers['val']?.text,
            cif: _controllers['cif']?.text,
          );
        }
      });
    }
  }

  Future<void> _saveSocData() async {
    try {
      // Fonction helper pour créer des Value avec gestion null explicite
      drift.Value<String?> createStringValue(String? text) {
        final trimmed = text?.trim();
        return trimmed == null || trimmed.isEmpty
            ? drift.Value(null) // Important: Value(null) pour les champs nullable
            : drift.Value(trimmed);
      }

      drift.Value<double?> createDoubleValue(String? text) {
        if (text == null || text.trim().isEmpty) {
          return drift.Value(null); // Value(null) pour les champs nullable
        }
        final value = double.tryParse(text.trim());
        return drift.Value(value); // Value(null) si conversion échoue
      }

      // Création du companion avec gestion correcte des null
      final companion = SocCompanion(
        ref: const drift.Value('SOC001'),
        rsoc: createStringValue(_controllers['rsoc']?.text),
        activites: createStringValue(_controllers['activites']?.text),
        adr: createStringValue(_controllers['adr']?.text),
        logo: drift.Value(_socData?.logo), // Peut être null
        capital: createDoubleValue(_controllers['capital']?.text),
        rcs: createStringValue(_controllers['rcs']?.text),
        nif: createStringValue(_controllers['nif']?.text),
        stat: createStringValue(_controllers['stat']?.text),
        tel: createStringValue(_controllers['tel']?.text),
        port: createStringValue(_controllers['port']?.text),
        email: createStringValue(_controllers['email']?.text),
        site: createStringValue(_controllers['site']?.text),
        fax: const drift.Value(null), // Explicitement null
        telex: const drift.Value(null), // Explicitement null
        tva: createDoubleValue(_controllers['tva']?.text),
        t: createDoubleValue(_controllers['t']?.text),
        val: createStringValue(_controllers['val']?.text),
        cif: createStringValue(_controllers['cif']?.text),
      );

      // Debug: Afficher les valeurs
      debugPrint('Valeurs à sauvegarder:');
      debugPrint('RSOC: ${_controllers['rsoc']?.text}');
      debugPrint('Activités: ${_controllers['activites']?.text}');
      debugPrint('Adresse: ${_controllers['adr']?.text}');
      debugPrint('Capital: ${_controllers['capital']?.text}');

      final db = DatabaseService().database;
      final existingSoc = await db.getSocByRef('SOC001');

      if (existingSoc == null) {
        // Insertion
        final id = await db.insertSoc(companion);
        debugPrint('Insertion réussie, ID: $id');
      } else {
        // Mise à jour - utilisez la méthode update directement
        await db.updateSoc(companion);
        debugPrint('Mise à jour réussie');
      }

      // Recharger pour vérifier
      final updated = await db.getSocByRef('SOC001');
      debugPrint('Après sauvegarde - RSOC: ${updated?.rsoc}');
      debugPrint('Après sauvegarde - Adresse: ${updated?.adr}');

      await _loadSocData();

      // Notification de succès
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              existingSoc == null ? 'Société créée avec succès' : 'Société mise à jour avec succès',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Erreur lors de la sauvegarde: $e');
      debugPrint('Stack trace: $stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de sauvegarde: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes.values) {
      focusNode.dispose();
    }
    super.dispose();
  }
}
