import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../database/database.dart';
import '../../database/database_service.dart';

class CompanyInfoModal extends StatefulWidget {
  const CompanyInfoModal({super.key});

  @override
  State<CompanyInfoModal> createState() => _CompanyInfoModalState();
}

class _CompanyInfoModalState extends State<CompanyInfoModal> {
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

    return Dialog(
      child: Container(
        width: 700,
        height: 600,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildHeader(isNewCompany),
            const SizedBox(height: 16),
            Expanded(child: _buildForm()),
            const SizedBox(height: 16),
            _buildLogoAndTaxSection(),
            const SizedBox(height: 16),
            _buildButtons(isNewCompany),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isNewCompany) {
    return Row(
      children: [
        const Icon(Icons.info, color: Colors.blue),
        const SizedBox(width: 8),
        Text(
          isNewCompany ? 'Enregistrer les informations de la société' : 'Information sur la société',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: [
              _buildEditableField('rsoc', 'Raison sociale'),
              _buildEditableField('activites', 'Activité'),
              _buildEditableMultilineField('adr', 'Adresse'),
              _buildEditableField('tel', 'Téléphone fixe'),
              _buildEditableField('email', 'Email'),
              _buildEditableField('site', 'Site web'),
            ],
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            children: [
              _buildEditableField('capital', 'Capital'),
              _buildEditableField('rcs', 'RCS'),
              _buildEditableField('nif', 'N.I.F'),
              _buildEditableField('stat', 'STAT'),
              _buildEditableField('cif', 'CIF'),
              _buildEditableField('port', 'Portable'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLogoAndTaxSection() {
    return Row(
      children: [
        GestureDetector(
          onTap: _selectLogo,
          child: Container(
            width: 120,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              border: Border.all(color: Colors.grey[400]!),
            ),
            child: _socData?.logo != null && _socData!.logo!.isNotEmpty
                ? Image.file(
                    File(_socData!.logo!),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Text('Logo', style: TextStyle(color: Colors.grey)),
                      );
                    },
                  )
                : const Center(
                    child: Text(
                      'Cliquer pour sélectionner',
                      style: TextStyle(color: Colors.grey, fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                  ),
          ),
        ),
        const Spacer(),
        SizedBox(
          width: 200,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildEditableField('tva', 'Taux TVA'),
              _buildEditableField('val', 'Valeur'),
              _buildEditableField('t', 'Taux T'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildButtons(bool isNewCompany) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        ElevatedButton(
          onPressed: () async {
            await _saveSocData();
            if (mounted) Navigator.of(context).pop();
          },
          child: Text(isNewCompany ? 'Enregistrer' : 'Modifier'),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(isNewCompany ? 'Annuler' : 'Fermer'),
        ),
      ],
    );
  }

  Widget _buildEditableField(String key, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(fontSize: 12)),
          ),
          Expanded(
            child: Container(
              height: 22,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[600]!, width: 1),
                color: Colors.white,
              ),
              child: TextFormField(
                controller: _controllers[key],
                style: const TextStyle(fontSize: 11),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                  isDense: true,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableMultilineField(String key, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(fontSize: 12)),
          ),
          Expanded(
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[600]!, width: 1),
                color: Colors.white,
              ),
              child: TextFormField(
                controller: _controllers[key],
                maxLines: 3,
                style: const TextStyle(fontSize: 11),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(3),
                  isDense: true,
                ),
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
            rsoc: null,
            activites: null,
            adr: null,
            logo: result.files.single.path,
            capital: null,
            rcs: null,
            nif: null,
            stat: null,
            tel: null,
            port: null,
            email: null,
            site: null,
            fax: null,
            telex: null,
            tva: null,
            t: null,
            val: null,
            cif: null,
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
