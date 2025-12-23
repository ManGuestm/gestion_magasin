import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants/app_functions.dart';
import '../../providers/vente_providers.dart';

/// Widget pour afficher le résumé des totaux
class SummaryTotalsWidget extends ConsumerWidget {
  final TextEditingController remiseController;
  final TextEditingController avanceController;
  final ValueChanged<double> onRemiseChanged;
  final ValueChanged<double> onAvanceChanged;

  const SummaryTotalsWidget({
    super.key,
    required this.remiseController,
    required this.avanceController,
    required this.onRemiseChanged,
    required this.onAvanceChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalHT = ref.watch(totalHTProvider);
    final totalTTC = ref.watch(totalTTCProvider);
    final reste = ref.watch(resteProvider);
    final newBalance = ref.watch(newClientBalanceProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTotalRow(context, 'Total HT:', AppFunctions.formatNumber(totalHT), false),
            const SizedBox(height: 8),
            _buildRemiseRow(context),
            const SizedBox(height: 8),
            _buildTotalRow(context, 'Total TTC:', AppFunctions.formatNumber(totalTTC), true),
            const SizedBox(height: 8),
            _buildAvanceRow(context),
            const SizedBox(height: 8),
            _buildTotalRow(context, 'Reste à payer:', AppFunctions.formatNumber(reste), true),
            const SizedBox(height: 12),
            Divider(),
            const SizedBox(height: 12),
            _buildTotalRow(
              context,
              'Nouveau solde client:',
              AppFunctions.formatNumber(newBalance),
              true,
              valueColor: newBalance > 0 ? Colors.red : Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalRow(BuildContext context, String label, String value, bool isBold, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        Text(
          value,
          style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: valueColor),
        ),
      ],
    );
  }

  Widget _buildRemiseRow(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text('Remise (%):', style: Theme.of(context).textTheme.bodyMedium)),
        SizedBox(
          width: 100,
          child: TextField(
            controller: remiseController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (value) => onRemiseChanged(double.tryParse(value) ?? 0.0),
            decoration: InputDecoration(border: OutlineInputBorder(), isDense: true),
          ),
        ),
      ],
    );
  }

  Widget _buildAvanceRow(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text('Avance:', style: Theme.of(context).textTheme.bodyMedium)),
        SizedBox(
          width: 100,
          child: TextField(
            controller: avanceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (value) => onAvanceChanged(double.tryParse(value) ?? 0.0),
            decoration: InputDecoration(border: OutlineInputBorder(), isDense: true),
          ),
        ),
      ],
    );
  }
}
