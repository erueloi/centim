import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/providers/repository_providers.dart';

import 'package:centim/l10n/app_localizations.dart';

class SetupGroupScreen extends ConsumerStatefulWidget {
  const SetupGroupScreen({super.key});

  @override
  ConsumerState<SetupGroupScreen> createState() => _SetupGroupScreenState();
}

class _SetupGroupScreenState extends ConsumerState<SetupGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  bool _isLoading = false;

  Future<void> _createGroup() async {
    if (_nameController.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final authRepo = ref.read(authRepositoryProvider);
      final groupRepo = ref.read(groupRepositoryProvider);
      final user = authRepo.currentUser;
      if (user == null) return;

      final groupId = await groupRepo.createGroup(
        _nameController.text,
        user.uid,
      );
      await authRepo.updateCurrentGroupId(groupId);

      // Navigate to Home/Dashboard
      // Ideally trigger a re-eval of auth state or router redirection
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _joinGroup() async {
    if (_codeController.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final authRepo = ref.read(authRepositoryProvider);
      final groupRepo = ref.read(groupRepositoryProvider);
      final user = authRepo.currentUser;
      if (user == null) return;

      await groupRepo.joinGroup(_codeController.text, user.uid);
      await authRepo.updateCurrentGroupId(_codeController.text);

      // Navigate to Home
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.setupGroupTitle)),
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Card(
              margin: const EdgeInsets.all(16.0),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              l10n.createGroupTitle,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).primaryColor,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            TextField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                labelText: l10n.groupNameLabel,
                                // border property is removed to use Theme defaults (Underline)
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: _createGroup,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                              child: Text(l10n.createGroupButton),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 32.0),
                              child: Divider(),
                            ),
                            Text(
                              l10n.orJoinGroupText,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).primaryColor,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            TextField(
                              controller:
                                  _codeController, // Keeping name to minimize diff, but logic changes
                              textCapitalization: TextCapitalization
                                  .characters, // Force uppercase
                              decoration: InputDecoration(
                                labelText: l10n.groupIdLabel,
                                hintText: 'Ex: AB12CD',
                                // border property is removed to use Theme defaults (Underline)
                              ),
                            ),
                            const SizedBox(height: 24),
                            OutlinedButton(
                              // Already was Outlined, ensuring style via Theme
                              onPressed: _joinGroup,
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                              child: Text(l10n.joinGroupButton),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
