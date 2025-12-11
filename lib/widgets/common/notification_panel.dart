import 'package:flutter/material.dart';
import '../../services/notification_service.dart';

class NotificationPanel extends StatelessWidget {
  const NotificationPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: NotificationService(),
      builder: (context, child) {
        final service = NotificationService();
        
        return PopupMenuButton<String>(
          icon: Stack(
            children: [
              const Icon(Icons.notifications),
              if (service.unreadCount > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${service.unreadCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          tooltip: 'Notifications',
          itemBuilder: (context) {
            if (service.notifications.isEmpty) {
              return [
                const PopupMenuItem(
                  enabled: false,
                  child: Text('Aucune notification'),
                ),
              ];
            }

            final items = <PopupMenuEntry<String>>[];
            
            // Header
            items.add(
              PopupMenuItem(
                enabled: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Notifications',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (service.unreadCount > 0)
                      TextButton(
                        onPressed: () {
                          service.markAllAsRead();
                          Navigator.pop(context);
                        },
                        child: const Text('Tout marquer lu'),
                      ),
                  ],
                ),
              ),
            );

            items.add(const PopupMenuDivider());

            // Notifications (max 5)
            final notifications = service.notifications.take(5).toList();
            for (final notification in notifications) {
              items.add(
                PopupMenuItem(
                  value: notification.id,
                  child: NotificationItem(notification: notification),
                ),
              );
            }

            if (service.notifications.length > 5) {
              items.add(const PopupMenuDivider());
              items.add(
                PopupMenuItem(
                  value: 'show_all',
                  child: Text(
                    'Voir toutes (${service.notifications.length})',
                    style: const TextStyle(color: Colors.blue),
                  ),
                ),
              );
            }

            return items;
          },
          onSelected: (value) {
            if (value == 'show_all') {
              _showAllNotifications(context);
            } else {
              NotificationService().markAsRead(value);
            }
          },
        );
      },
    );
  }

  void _showAllNotifications(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const NotificationDialog(),
    );
  }
}

class NotificationItem extends StatelessWidget {
  final AppNotification notification;

  const NotificationItem({super.key, required this.notification});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: notification.isRead ? null : Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                _getNotificationIcon(notification.type),
                size: 16,
                color: _getNotificationColor(notification.type),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  notification.title,
                  style: TextStyle(
                    fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                _formatTime(notification.timestamp),
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            notification.message,
            style: const TextStyle(fontSize: 11),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.info:
        return Icons.info;
      case NotificationType.warning:
        return Icons.warning;
      case NotificationType.error:
        return Icons.error;
      case NotificationType.success:
        return Icons.check_circle;
    }
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.info:
        return Colors.blue;
      case NotificationType.warning:
        return Colors.orange;
      case NotificationType.error:
        return Colors.red;
      case NotificationType.success:
        return Colors.green;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    
    if (diff.inMinutes < 1) return 'maintenant';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}j';
  }
}

class NotificationDialog extends StatelessWidget {
  const NotificationDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Toutes les notifications'),
      content: SizedBox(
        width: 400,
        height: 500,
        child: ListenableBuilder(
          listenable: NotificationService(),
          builder: (context, child) {
            final notifications = NotificationService().notifications;
            
            if (notifications.isEmpty) {
              return const Center(
                child: Text('Aucune notification'),
              );
            }

            return ListView.separated(
              itemCount: notifications.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return ListTile(
                  leading: Icon(
                    _getNotificationIcon(notification.type),
                    color: _getNotificationColor(notification.type),
                  ),
                  title: Text(
                    notification.title,
                    style: TextStyle(
                      fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(notification.message),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _formatDateTime(notification.timestamp),
                        style: const TextStyle(fontSize: 10),
                      ),
                      if (!notification.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  onTap: () {
                    NotificationService().markAsRead(notification.id);
                  },
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => NotificationService().clearAll(),
          child: const Text('Tout effacer'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fermer'),
        ),
      ],
    );
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.info:
        return Icons.info;
      case NotificationType.warning:
        return Icons.warning;
      case NotificationType.error:
        return Icons.error;
      case NotificationType.success:
        return Icons.check_circle;
    }
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.info:
        return Colors.blue;
      case NotificationType.warning:
        return Colors.orange;
      case NotificationType.error:
        return Colors.red;
      case NotificationType.success:
        return Colors.green;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}