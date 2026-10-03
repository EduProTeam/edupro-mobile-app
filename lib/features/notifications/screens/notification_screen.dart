import 'package:flutter/material.dart';

import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final NotificationService _notificationService = NotificationService();

  bool _showUnreadOnly = false;

  static const Color primaryBlue = Color(0xFF3D8FEF);

  static const Color backgroundColor = Color(0xFFF6F7FB);

  static const Color darkText = Color(0xFF151A24);

  static const Color secondaryText = Color(0xFF8A94A6);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,

      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Notifications',
          style: TextStyle(color: darkText, fontWeight: FontWeight.w800),
        ),
      ),

      body: Column(
        children: [
          const SizedBox(height: 14),

          // ==========================================
          // ALL / UNREAD
          // ==========================================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildFilterButton(
                  title: 'All',
                  selected: !_showUnreadOnly,
                  onTap: () {
                    setState(() {
                      _showUnreadOnly = false;
                    });
                  },
                ),

                const SizedBox(width: 10),

                _buildFilterButton(
                  title: 'Unread',
                  selected: _showUnreadOnly,
                  onTap: () {
                    setState(() {
                      _showUnreadOnly = true;
                    });
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          Expanded(
            child: StreamBuilder<List<AppNotificationModel>>(
              stream: _notificationService.getNotifications(),

              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: primaryBlue),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Could not load notifications.\n'
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  );
                }

                var notifications = snapshot.data ?? [];

                if (_showUnreadOnly) {
                  notifications = notifications
                      .where((notification) => !notification.isRead)
                      .toList();
                }

                if (notifications.isEmpty) {
                  return Center(
                    child: Text(
                      _showUnreadOnly
                          ? 'No unread notifications.'
                          : 'No notifications yet.',
                      style: const TextStyle(color: secondaryText),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  itemCount: notifications.length,

                  separatorBuilder: (_, __) => const SizedBox(height: 10),

                  itemBuilder: (context, index) {
                    final notification = notifications[index];

                    return _buildNotificationCard(notification);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FILTER BUTTON
  // ============================================================

  Widget _buildFilterButton({
    required String title,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? primaryBlue : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? primaryBlue : const Color(0xFFD9DEE7),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: selected ? Colors.white : darkText,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // NOTIFICATION CARD
  // ============================================================

  Widget _buildNotificationCard(AppNotificationModel notification) {
    final unread = !notification.isRead;

    return Material(
      color: unread ? const Color(0xFFEFF6FF) : Colors.white,

      borderRadius: BorderRadius.circular(14),

      child: InkWell(
        borderRadius: BorderRadius.circular(14),

        onTap: () async {
          if (!notification.isRead) {
            await _notificationService.markAsRead(notification.id);
          }
        },

        child: Container(
          padding: const EdgeInsets.all(14),

          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFD9DEE7)),
          ),

          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              // Icon
              Container(
                width: 44,
                height: 44,

                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _getIconColor(
                    notification.type,
                  ).withValues(alpha: 0.10),
                ),

                child: Icon(
                  _getIcon(notification.type),
                  color: _getIconColor(notification.type),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,

                            style: TextStyle(
                              color: darkText,
                              fontSize: 14,
                              fontWeight: unread
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                            ),
                          ),
                        ),

                        if (unread)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 5),

                    Text(
                      notification.message,
                      style: const TextStyle(
                        color: secondaryText,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      _formatDate(notification.createdAt),
                      style: const TextStyle(
                        color: Color(0xFFA0A8B5),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ICON
  // ============================================================

  IconData _getIcon(String type) {
    switch (type) {
      case 'admin_changed':
        return Icons.admin_panel_settings_outlined;

      case 'member_joined':
        return Icons.person_add_alt_1;

      case 'group_deleted':
        return Icons.delete_outline;

      default:
        return Icons.notifications_none_rounded;
    }
  }

  Color _getIconColor(String type) {
    switch (type) {
      case 'admin_changed':
        return primaryBlue;

      case 'member_joined':
        return Colors.green;

      case 'group_deleted':
        return Colors.redAccent;

      default:
        return primaryBlue;
    }
  }

  // ============================================================
  // DATE
  // ============================================================

  String _formatDate(DateTime? date) {
    if (date == null) {
      return 'Just now';
    }

    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    }

    if (difference.inHours < 24) {
      return '${difference.inHours} hr ago';
    }

    if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    }

    return '${date.day}/${date.month}/${date.year}';
  }
}
