import 'dart:async';

import 'package:flutter/material.dart';

import '../database/database_service.dart';

enum NotificationType { info, warning, error, success }

class AppNotification {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic>? data;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.data,
  });

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      title: title,
      message: message,
      type: type,
      timestamp: timestamp,
      isRead: isRead ?? this.isRead,
      data: data,
    );
  }
}

class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final List<AppNotification> _notifications = [];
  Timer? _stockCheckTimer;

  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  /// Initialise le service de notifications
  void initialize() {
    _startStockMonitoring();
  }

  /// Ajoute une notification
  void addNotification({
    required String title,
    required String message,
    required NotificationType type,
    Map<String, dynamic>? data,
  }) {
    final notification = AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      type: type,
      timestamp: DateTime.now(),
      data: data,
    );

    _notifications.insert(0, notification);

    // Limiter à 50 notifications
    if (_notifications.length > 50) {
      _notifications.removeRange(50, _notifications.length);
    }

    notifyListeners();
  }

  /// Marque une notification comme lue
  void markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      notifyListeners();
    }
  }

  /// Marque toutes les notifications comme lues
  void markAllAsRead() {
    for (int i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
    notifyListeners();
  }

  /// Supprime une notification
  void removeNotification(String id) {
    _notifications.removeWhere((n) => n.id == id);
    notifyListeners();
  }

  /// Vide toutes les notifications
  void clearAll() {
    _notifications.clear();
    notifyListeners();
  }

  /// Démarre la surveillance des stocks
  void _startStockMonitoring() {
    _stockCheckTimer?.cancel();
    _stockCheckTimer = Timer.periodic(const Duration(hours: 1), (_) {
      _checkLowStock();
    });

    // Vérification initiale
    Future.delayed(const Duration(seconds: 5), _checkLowStock);
  }

  /// Vérifie les stocks faibles
  Future<void> _checkLowStock() async {
    try {
      final db = DatabaseService().database;
      final articles = await db.getActiveArticles();

      int lowStockCount = 0;
      int outOfStockCount = 0;

      for (final article in articles) {
        final totalStock = (article.stocksu1 ?? 0) + (article.stocksu2 ?? 0) + (article.stocksu3 ?? 0);

        if (totalStock <= 0) {
          outOfStockCount++;
        } else if (article.usec != null && totalStock <= article.usec!) {
          lowStockCount++;
        }
      }

      if (outOfStockCount > 0) {
        addNotification(
          title: 'Articles en rupture',
          message: '$outOfStockCount article(s) en rupture de stock',
          type: NotificationType.error,
          data: {'type': 'stock', 'count': outOfStockCount},
        );
      }

      if (lowStockCount > 0) {
        addNotification(
          title: 'Stock faible',
          message: '$lowStockCount article(s) avec stock faible',
          type: NotificationType.warning,
          data: {'type': 'low_stock', 'count': lowStockCount},
        );
      }
    } catch (e) {
      addNotification(
        title: 'Erreur surveillance',
        message: 'Erreur lors de la vérification des stocks',
        type: NotificationType.error,
      );
    }
  }

  /// Arrête la surveillance
  @override
  void dispose() {
    _stockCheckTimer?.cancel();
    super.dispose();
  }

  /// Notifications prédéfinies
  void notifyBackupSuccess(String fileName) {
    addNotification(
      title: 'Sauvegarde réussie',
      message: 'Sauvegarde créée: $fileName',
      type: NotificationType.success,
    );
  }

  void notifyBackupError(String error) {
    addNotification(
      title: 'Erreur sauvegarde',
      message: 'Échec de la sauvegarde: $error',
      type: NotificationType.error,
    );
  }

  void notifyDataImported(int count) {
    addNotification(
      title: 'Import terminé',
      message: '$count enregistrement(s) importé(s)',
      type: NotificationType.success,
    );
  }

  void notifySystemError(String error) {
    addNotification(title: 'Erreur système', message: error, type: NotificationType.error);
  }
}
