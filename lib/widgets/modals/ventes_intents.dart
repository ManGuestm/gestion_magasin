import 'package:flutter/widgets.dart';

// Intents pour les raccourcis clavier du modal ventes
class SaveIntent extends Intent {
  const SaveIntent();
}

class NewSaleIntent extends Intent {
  const NewSaleIntent();
}

class CancelSaleIntent extends Intent {
  const CancelSaleIntent();
}

class PrintInvoiceIntent extends Intent {
  const PrintInvoiceIntent();
}

class PrintBLIntent extends Intent {
  const PrintBLIntent();
}

class SearchArticleIntent extends Intent {
  const SearchArticleIntent();
}

class LastJournalIntent extends Intent {
  const LastJournalIntent();
}

class LastCanceledIntent extends Intent {
  const LastCanceledIntent();
}

class CloseIntent extends Intent {
  const CloseIntent();
}

class ValidateIntent extends Intent {
  const ValidateIntent();
}