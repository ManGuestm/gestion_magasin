import 'package:flutter/material.dart';

import '../../common/mode_paiement_dropdown.dart';
import 'ventes_controller.dart';

class VentesSummarySection extends StatelessWidget {
  final VentesController controller;
  final bool tousDepots;

  const VentesSummarySection({
    super.key,
    required this.controller,
    required this.tousDepots,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left side - Payment details
          _buildPaymentSection(),
          const SizedBox(width: 16),
          // Right side - Invoice totals
          if (!controller.isVendeur()) _buildInvoiceSummary(),
        ],
      ),
    );
  }

  Widget _buildPaymentSection() {
    return Expanded(
      flex: 2,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'MODE DE PAIEMENT',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 25,
              width: double.infinity,
              child: ModePaiementDropdown(
                selectedMode: controller.selectedModePaiement,
                showCreditMode: controller.showCreditMode && !controller.isVendeur(),
                tousDepots: tousDepots,
                onChanged: controller.setSelectedModePaiement,
              ),
            ),
            const SizedBox(height: 8),
            if (controller.showCreditMode && !controller.isVendeur() && tousDepots) ...[
              const SizedBox(height: 12),
              // Solde antérieur
              Row(
                children: [
                  const Text('Solde antérieur:', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 25,
                      child: TextField(
                        controller: controller.soldeAnterieurController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          fillColor: Color(0xFFF5F5F5),
                          filled: true,
                        ),
                        style: const TextStyle(fontSize: 12),
                        textAlign: TextAlign.right,
                        readOnly: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Nouveau solde
              Row(
                children: [
                  Text(
                    controller.selectedModePaiement == 'A crédit' ? 'Solde dû client:' : 'Nouveau solde:',
                    style: TextStyle(
                      fontSize: 12,
                      color: controller.selectedModePaiement == 'A crédit' ? Colors.red : Colors.black,
                      fontWeight:
                          controller.selectedModePaiement == 'A crédit' ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 25,
                      child: TextField(
                        controller: controller.nouveauSoldeController,
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          fillColor: controller.selectedModePaiement == 'A crédit'
                              ? Colors.red.shade50
                              : const Color(0xFFF5F5F5),
                          filled: true,
                        ),
                        style: TextStyle(
                          fontSize: 12,
                          color: controller.selectedModePaiement == 'A crédit' ? Colors.red : Colors.black,
                          fontWeight: controller.selectedModePaiement == 'A crédit'
                              ? FontWeight.w500
                              : FontWeight.normal,
                        ),
                        readOnly: true,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceSummary() {
    return Expanded(
      flex: 2,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(4),
          color: Colors.grey.shade50,
        ),
        child: Column(
          children: [
            const Text(
              'RÉCAPITULATIF FACTURE',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            // Remise
            _buildRemiseRow(),
            const Divider(height: 16),
            // Total TTC
            _buildTotalTTCRow(),
          ],
        ),
      ),
    );
  }

  Widget _buildRemiseRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Text('Remise:', style: TextStyle(fontSize: 12)),
            const SizedBox(width: 4),
            SizedBox(
              width: 50,
              height: 25,
              child: TextField(
                controller: controller.remiseController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  suffixText: '%',
                ),
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
                onChanged: (value) => controller.calculerTotaux(),
                readOnly: controller.selectedVerification == 'JOURNAL',
              ),
            ),
          ],
        ),
        SizedBox(
          width: 100,
          height: 25,
          child: TextField(
            controller: TextEditingController(
              text: _calculateRemiseAmount(),
            ),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              fillColor: Colors.white,
              filled: true,
            ),
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.right,
            readOnly: true,
          ),
        ),
      ],
    );
  }

  Widget _buildTotalTTCRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'TOTAL TTC:',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
        SizedBox(
          width: 100,
          height: 30,
          child: TextField(
            controller: controller.totalTTCController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            ),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
            textAlign: TextAlign.right,
            readOnly: true,
          ),
        ),
      ],
    );
  }

  String _calculateRemiseAmount() {
    // Implémenter le calcul de la remise
    return '0';
  }
}
