import 'package:flutter/widgets.dart';

// Intents pour les raccourcis clavier du modal achats
class SavePurchaseIntent extends Intent {
  const SavePurchaseIntent();
}

class NewPurchaseIntent extends Intent {
  const NewPurchaseIntent();
}

class CancelPurchaseIntent extends Intent {
  const CancelPurchaseIntent();
}

class PrintReceiptIntent extends Intent {
  const PrintReceiptIntent();
}

class SearchArticleIntent extends Intent {
  const SearchArticleIntent();
}

class LastJournalIntent extends Intent {
  const LastJournalIntent();
}

class LastDraftIntent extends Intent {
  const LastDraftIntent();
}

class LastCanceledIntent extends Intent {
  const LastCanceledIntent();
}

class CloseIntent extends Intent {
  const CloseIntent();
}

class ClearFieldIntent extends Intent {
  const ClearFieldIntent();
}

class ValidateIntent extends Intent {
  const ValidateIntent();
}