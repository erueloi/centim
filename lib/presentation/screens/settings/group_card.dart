import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/providers/repository_providers.dart';
import '../../../domain/models/household_group.dart';
import '../../../domain/models/user_profile.dart';
import '../../providers/group_providers.dart';

/// Grup actual: codi d'invitació i administració de membres.
///
/// - L'owner pot treure membres, traspassar-ne la propietat i regenerar el codi.
/// - Qualsevol altre membre pot sortir del grup.
/// Les regles de Firestore apliquen les mateixes restriccions al servidor.
class GroupCard extends ConsumerWidget {
  const GroupCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final group = ref.watch(currentGroupProvider).valueOrNull;
    if (group == null) return const SizedBox.shrink();

    final myUid = ref.watch(currentUidProvider);
    final isOwner = myUid != null && myUid == group.ownerId;
    final profiles = {
      for (final p in ref.watch(groupMembersProvider).valueOrNull ?? <UserProfile>[])
        p.uid: p,
    };

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'El meu grup',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.home_outlined, color: AppTheme.copper),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  group.name,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              Text(
                '${group.memberIds.length} '
                '${group.memberIds.length == 1 ? 'membre' : 'membres'}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _InviteCodeField(group: group, isOwner: isOwner),
          const SizedBox(height: 8),
          const Text(
            'Comparteix aquest codi amb qui vulguis convidar: l\'haurà '
            'd\'introduir a «Unir-se a un grup» en registrar-se.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Text(
            'Membres',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          for (final uid in group.memberIds)
            _MemberTile(
              group: group,
              uid: uid,
              profile: profiles[uid],
              isMe: uid == myUid,
              canManage: isOwner && uid != myUid,
            ),
          const SizedBox(height: 8),
          if (!isOwner && myUid != null)
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: () => _leaveGroup(context, ref, group, myUid),
                icon: const Icon(Icons.logout, color: Colors.red, size: 18),
                label: const Text(
                  'Sortir del grup',
                  style: TextStyle(color: Colors.red),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                ),
              ),
            )
          else if (isOwner && group.memberIds.length > 1)
            const Text(
              'Ets el propietari del grup. Per sortir-ne, primer fes '
              'propietari un altre membre.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
        ],
      ),
    );
  }

  Future<void> _leaveGroup(
    BuildContext context,
    WidgetRef ref,
    HouseholdGroup group,
    String myUid,
  ) async {
    final ok = await _confirm(
      context,
      title: 'Sortir del grup?',
      message: 'Deixaràs de veure les dades de «${group.name}». Per tornar-hi '
          'necessitaràs el codi d\'invitació.',
      confirmLabel: 'Sortir',
    );
    if (!ok || !context.mounted) return;
    await _run(
      context,
      () => ref.read(groupRepositoryProvider).leaveGroup(group.id, myUid),
    );
  }
}

class _InviteCodeField extends ConsumerWidget {
  final HouseholdGroup group;
  final bool isOwner;
  const _InviteCodeField({required this.group, required this.isOwner});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.only(left: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: SelectableText(
              group.inviteCode,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
            ),
          ),
          if (isOwner)
            IconButton(
              tooltip: 'Generar un codi nou',
              icon: const Icon(Icons.refresh, color: AppTheme.copper),
              onPressed: () => _regenerate(context, ref),
            ),
          IconButton(
            tooltip: 'Copiar el codi',
            icon: const Icon(Icons.copy, color: AppTheme.copper),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: group.inviteCode));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Codi copiat.')),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _regenerate(BuildContext context, WidgetRef ref) async {
    final ok = await _confirm(
      context,
      title: 'Generar un codi nou?',
      message: 'El codi actual (${group.inviteCode}) deixarà de funcionar. '
          'Els membres actuals no es veuen afectats.',
      confirmLabel: 'Generar',
      destructive: false,
    );
    if (!ok || !context.mounted) return;
    await _run(
      context,
      () => ref.read(groupRepositoryProvider).regenerateInviteCode(group.id),
      success: 'Codi nou generat.',
    );
  }
}

class _MemberTile extends ConsumerWidget {
  final HouseholdGroup group;
  final String uid;
  final UserProfile? profile;
  final bool isMe;
  final bool canManage;

  const _MemberTile({
    required this.group,
    required this.uid,
    required this.profile,
    required this.isMe,
    required this.canManage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = profile?.name?.trim();
    final email = profile?.email;
    final hasName = name != null && name.isNotEmpty;
    final title = hasName
        ? name
        : (email?.isNotEmpty ?? false)
            ? email!
            : 'Usuari sense perfil';
    final subtitle = hasName ? email : (profile == null ? uid : null);
    final isOwner = uid == group.ownerId;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: AppTheme.copper.withValues(alpha: 0.15),
        child: Icon(
          isOwner ? Icons.star : Icons.person,
          size: 18,
          color: AppTheme.copper,
        ),
      ),
      title: Text(
        isMe ? '$title (tu)' : title,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: subtitle == null
          ? (isOwner ? const Text('Propietari') : null)
          : Text(
              isOwner ? '$subtitle · Propietari' : subtitle,
              overflow: TextOverflow.ellipsis,
            ),
      trailing: canManage
          ? PopupMenuButton<_MemberAction>(
              tooltip: 'Opcions del membre',
              onSelected: (action) => _onAction(context, ref, action, title),
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: _MemberAction.makeOwner,
                  child: Text('Fer-lo propietari'),
                ),
                PopupMenuItem(
                  value: _MemberAction.remove,
                  child: Text(
                    'Treure del grup',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            )
          : null,
    );
  }

  Future<void> _onAction(
    BuildContext context,
    WidgetRef ref,
    _MemberAction action,
    String title,
  ) async {
    final repo = ref.read(groupRepositoryProvider);
    switch (action) {
      case _MemberAction.remove:
        final ok = await _confirm(
          context,
          title: 'Treure $title del grup?',
          message: 'Deixarà de veure les dades de «${group.name}». Si hi ha de '
              'tornar, necessitarà el codi d\'invitació (pots generar-ne un '
              'de nou perquè l\'actual no li serveixi).',
          confirmLabel: 'Treure',
        );
        if (!ok || !context.mounted) return;
        await _run(
          context,
          () => repo.removeMember(group.id, uid),
          success: '$title ja no és membre del grup.',
        );
      case _MemberAction.makeOwner:
        final ok = await _confirm(
          context,
          title: 'Fer $title propietari?',
          message: 'Deixaràs de ser el propietari: només $title podrà '
              'gestionar membres i el codi d\'invitació.',
          confirmLabel: 'Traspassar',
        );
        if (!ok || !context.mounted) return;
        await _run(
          context,
          () => repo.transferOwnership(group.id, uid),
          success: '$title és ara el propietari del grup.',
        );
    }
  }
}

enum _MemberAction { makeOwner, remove }

Future<bool> _confirm(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = true,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel·lar'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(
            confirmLabel,
            style: TextStyle(color: destructive ? Colors.red : null),
          ),
        ),
      ],
    ),
  );
  return result ?? false;
}

Future<void> _run(
  BuildContext context,
  Future<void> Function() action, {
  String? success,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    await action();
    if (success != null) {
      messenger.showSnackBar(SnackBar(content: Text(success)));
    }
  } catch (e) {
    messenger.showSnackBar(
      SnackBar(content: Text('No s\'ha pogut completar: $e')),
    );
  }
}
