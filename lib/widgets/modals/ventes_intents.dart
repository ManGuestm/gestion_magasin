// Définir les classes Intent
import 'package:flutter/material.dart';

class SaveIntent extends Intent {
  const SaveIntent();
}

class NewSaleIntent extends Intent {
  const NewSaleIntent();
}

class CancelSaleIntent extends Intent {
  const CancelSaleIntent();
}

class CloseIntent extends Intent {
  const CloseIntent();
}

class ValidateIntent extends Intent {
  const ValidateIntent();
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
