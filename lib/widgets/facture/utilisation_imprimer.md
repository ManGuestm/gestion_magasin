// Pour une facture

final config = PdfConfig(
  documentType: DocumentType.facture,
  selectedFormat: 'A4',
  documentNumber: 'F-2025-001',
  date: '26/12/2025',
  client: 'Client ABC',
  lignes: lignesVente,
  totalTTC: 150000,
  remise: 5000,
  societe: maSociete,
  modePaiement: 'Espèces',
);

await PdfGenerator.printDocument(context, config);

// Pour un bon de livraison
final configBL = PdfConfig(
  documentType: DocumentType.bonLivraison,
  selectedFormat: 'A6',
  documentNumber: 'BL-2025-001',
  date: '26/12/2025',
  client: 'Client XYZ',
  lignes: lignesLivraison,
  totalTTC: 75000,
  societe: maSociete,
  showDepot: true,
);

await PdfGenerator.printDocument(context, configBL);