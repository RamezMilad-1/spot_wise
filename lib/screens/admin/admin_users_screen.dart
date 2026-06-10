import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/app_user.dart';
import '../../models/enums.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/badges.dart';
import '../../widgets/feedback.dart';
import '../../widgets/state_views.dart';
import '../../widgets/user_avatar.dart';

/// Admin user management: search users, promote/demote admins, suspend,
/// delete, and send notifications (to one user or broadcast to everyone).
class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<AdminProvider>().loadUsers(),
    );
  }

  Future<void> _setRole(AppUser u, UserRole role) async {
    await context.read<AdminProvider>().setUserRole(u, role);
    if (mounted) {
      AppSnackbar.success(context, '${u.name} is now ${role.label}.');
    }
  }

  Future<void> _toggleSuspend(AppUser u) async {
    await context.read<AdminProvider>().toggleSuspended(u);
    if (mounted) {
      AppSnackbar.show(
        context,
        u.suspended ? '${u.name} reinstated.' : '${u.name} suspended.',
      );
    }
  }

  Future<void> _notify(AppUser u) async {
    final msg = await _composeNotification(context, target: u.name);
    if (msg == null || !mounted) return;
    await context.read<AdminProvider>().notifyUser(u, msg.$1, msg.$2);
    if (mounted) {
      AppSnackbar.success(context, 'Notification sent to ${u.name}.');
    }
  }

  Future<void> _delete(AppUser u) async {
    final ok = await showConfirmSheet(
      context,
      title: 'Delete ${u.name}?',
      message: 'Their account is removed and they can no longer sign in.',
      confirmLabel: 'Delete',
      icon: Icons.person_remove_alt_1_outlined,
      destructive: true,
    );
    if (!ok || !mounted) return;
    await context.read<AdminProvider>().deleteUser(u);
    if (mounted) AppSnackbar.show(context, '${u.name} deleted.');
  }

  Future<void> _notifyAll() async {
    final adminP = context.read<AdminProvider>();
    final msg = await _composeNotification(
      context,
      target: 'all ${adminP.userCount} users',
    );
    if (msg == null || !mounted) return;
    await adminP.notifyAllUsers(msg.$1, msg.$2);
    if (mounted) {
      AppSnackbar.success(
        context,
        'Broadcast sent to ${adminP.userCount} users.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminP = context.watch<AdminProvider>();
    final myId = context.read<AuthProvider>().user?.id;
    final q = _query.trim().toLowerCase();
    final users = q.isEmpty
        ? adminP.users
        : adminP.users
              .where((u) => '${u.name} ${u.email}'.toLowerCase().contains(q))
              .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage users'),
        actions: [
          IconButton(
            tooltip: 'Notify all users',
            icon: const Icon(Icons.campaign_outlined),
            onPressed: adminP.users.isEmpty ? null : _notifyAll,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search_rounded),
                hintText: 'Search by name or email',
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: adminP.loadingUsers && adminP.users.isEmpty
                ? const LoadingView()
                : users.isEmpty
                ? const EmptyView(
                    icon: Icons.group_outlined,
                    title: 'No users',
                    message: 'Nothing matches your search yet.',
                  )
                : RefreshIndicator(
                    onRefresh: () => adminP.loadUsers(),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        0,
                        AppSpacing.lg,
                        AppSpacing.lg,
                      ),
                      itemCount: users.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.md),
                      itemBuilder: (_, i) {
                        final u = users[i];
                        return _UserCard(
                          user: u,
                          isSelf: u.id == myId,
                          onMakeAdmin: () => _setRole(u, UserRole.admin),
                          onMakeExplorer: () => _setRole(u, UserRole.user),
                          onToggleSuspend: () => _toggleSuspend(u),
                          onNotify: () => _notify(u),
                          onDelete: () => _delete(u),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Title + message composer dialog. Returns (title, body) or null if cancelled.
Future<(String, String)?> _composeNotification(
  BuildContext context, {
  required String target,
}) {
  final titleC = TextEditingController();
  final bodyC = TextEditingController();
  return showDialog<(String, String)>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Notify $target'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: titleC,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Title'),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: bodyC,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Message'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final t = titleC.text.trim();
            final b = bodyC.text.trim();
            if (t.isEmpty || b.isEmpty) return;
            Navigator.pop(ctx, (t, b));
          },
          child: const Text('Send'),
        ),
      ],
    ),
  );
}

class _UserCard extends StatelessWidget {
  final AppUser user;
  final bool isSelf;
  final VoidCallback onMakeAdmin;
  final VoidCallback onMakeExplorer;
  final VoidCallback onToggleSuspend;
  final VoidCallback onNotify;
  final VoidCallback onDelete;

  const _UserCard({
    required this.user,
    required this.isSelf,
    required this.onMakeAdmin,
    required this.onMakeExplorer,
    required this.onToggleSuspend,
    required this.onNotify,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            UserAvatar(
              photoUrl: user.photoUrl,
              initials: user.initials,
              radius: 24,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          user.name,
                          style: text.titleSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isSelf) ...[
                        const SizedBox(width: 6),
                        const Pill(
                          label: 'You',
                          icon: Icons.person_rounded,
                          color: AppColors.teal,
                        ),
                      ],
                    ],
                  ),
                  Text(
                    user.email,
                    style: text.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      Pill(
                        label: user.role.label,
                        icon: user.role.icon,
                        color: Theme.of(context).colorScheme.onSurface,
                        background: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                      ),
                      if (user.suspended)
                        const Pill(
                          label: 'Suspended',
                          icon: Icons.block_rounded,
                          color: AppColors.danger,
                        ),
                      if (user.homeCity != null && user.homeCity!.isNotEmpty)
                        Pill(
                          label: user.homeCity!,
                          icon: Icons.place_outlined,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          background: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            if (!isSelf)
              PopupMenuButton<String>(
                onSelected: (v) {
                  switch (v) {
                    case 'admin':
                      onMakeAdmin();
                    case 'explorer':
                      onMakeExplorer();
                    case 'suspend':
                      onToggleSuspend();
                    case 'notify':
                      onNotify();
                    case 'delete':
                      onDelete();
                  }
                },
                itemBuilder: (_) => [
                  if (user.role != UserRole.admin)
                    const PopupMenuItem(
                      value: 'admin',
                      child: Text('Make admin'),
                    )
                  else
                    const PopupMenuItem(
                      value: 'explorer',
                      child: Text('Make explorer'),
                    ),
                  PopupMenuItem(
                    value: 'suspend',
                    child: Text(user.suspended ? 'Reinstate' : 'Suspend'),
                  ),
                  const PopupMenuItem(
                    value: 'notify',
                    child: Text('Send notification'),
                  ),
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
