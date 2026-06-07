import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../models/notification_item.dart';
import '../../providers/notifications_provider.dart';
import '../../services/service_locator.dart';
import '../../widgets/state_views.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationItem> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = services.auth.currentUser?.id;
    final items = uid == null ? <NotificationItem>[] : await services.backend.getNotifications(uid);
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  Future<void> _markAllRead() async {
    await context.read<NotificationsProvider>().markAllRead();
    await _load();
  }

  Future<void> _open(NotificationItem n) async {
    if (!n.isRead) await context.read<NotificationsProvider>().markRead(n.id);
    if (n.spotId != null) {
      final spot = await services.backend.getSpot(n.spotId!);
      if (spot != null && mounted) {
        await Navigator.pushNamed(context, AppRoutes.spotDetails, arguments: spot);
      }
    }
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (_items.any((n) => !n.isRead))
            TextButton(onPressed: _markAllRead, child: const Text('Mark all read')),
        ],
      ),
      body: _loading
          ? const LoadingView()
          : _items.isEmpty
              ? const EmptyView(
                  icon: Icons.notifications_none_rounded,
                  title: 'You\'re all caught up',
                  message: 'Approvals, likes and reminders will show up here.',
                )
              : ListView.separated(
                  itemCount: _items.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) => _NotificationTile(item: _items[i], onTap: () => _open(_items[i])),
                ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationItem item;
  final VoidCallback onTap;
  const _NotificationTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      onTap: onTap,
      tileColor: item.isRead ? null : item.type.color.withValues(alpha: 0.06),
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
      leading: CircleAvatar(
        backgroundColor: item.type.color.withValues(alpha: 0.16),
        child: Icon(item.type.icon, color: item.type.color, size: 20),
      ),
      title: Text(item.title, style: Theme.of(context).textTheme.titleSmall),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.body),
          const SizedBox(height: 2),
          Text(Formatters.relative(item.createdAt), style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
      trailing: item.isRead
          ? null
          : Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: scheme.secondary, shape: BoxShape.circle),
            ),
    );
  }
}
