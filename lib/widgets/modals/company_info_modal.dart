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
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        border: Border(bottom: BorderSide(color: Colors.blue[100]!)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(8),
            ),
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
            child: Text(
              isNewCompany ? 'Annuler' : 'Fermer',
              style: TextStyle(color: Colors.grey[600]),
            ),
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
    _controllers['rsoc'] = TextEditingController(text: _socData?.rsoc ?? '');
    _controllers['activites'] = TextEditingController(text: _socData?.activites ?? '');
    _controllers['adr'] = TextEditingController(text: _socData?.adr ?? '');
    _controllers['tel'] = TextEditingController(text: _socData?.tel ?? '');
    _controllers['email'] = TextEditingController(text: _socData?.email ?? '');
    _controllers['site'] = TextEditingController(text: _socData?.site ?? '');
    _controllers['capital'] = TextEditingController(text: _socData?.capital?.toString() ?? '');
    _controllers['rcs'] = TextEditingController(text: _socData?.rcs ?? '');
    _controllers['nif'] = TextEditingController(text: _socData?.nif ?? '');
    _controllers['stat'] = TextEditingController(text: _socData?.stat ?? '');
    _controllers['cif'] = TextEditingController(text: _socData?.cif ?? '');
    _controllers['port'] = TextEditingController(text: _socData?.port ?? '');
    _controllers['tva'] = TextEditingController(text: _socData?.tva?.toString() ?? '');
    _controllers['val'] = TextEditingController(text: _socData?.val ?? '');
    _controllers['t'] = TextEditingController(text: _socData?.t?.toString() ?? '');
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
      final companion = SocCompanion(
        ref: const drift.Value('SOC001'),
        rsoc: drift.Value(_controllers['rsoc']?.text),
        activites: drift.Value(_controllers['activites']?.text),
        adr: drift.Value(_controllers['adr']?.text),
        logo: drift.Value(_socData?.logo),
        capital: drift.Value(double.tryParse(_controllers['capital']?.text ?? '')),
        rcs: drift.Value(_controllers['rcs']?.text),
        nif: drift.Value(_controllers['nif']?.text),
        stat: drift.Value(_controllers['stat']?.text),
        tel: drift.Value(_controllers['tel']?.text),
        port: drift.Value(_controllers['port']?.text),
        email: drift.Value(_controllers['email']?.text),
        site: drift.Value(_controllers['site']?.text),
        fax: const drift.Value(null),
        telex: const drift.Value(null),
        tva: drift.Value(double.tryParse(_controllers['tva']?.text ?? '')),
        t: drift.Value(double.tryParse(_controllers['t']?.text ?? '')),
        val: drift.Value(_controllers['val']?.text),
        cif: drift.Value(_controllers['cif']?.text),
      );

      final existingSoc = await DatabaseService().database.getSocByRef('SOC001');
      if (existingSoc == null) {
        await DatabaseService().database.insertSoc(companion);
      } else {
        await DatabaseService().database.updateSoc(companion);
      }

      await _loadSocData();
    } catch (e) {
      debugPrint('Erreur lors de la sauvegarde: $e');
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}
