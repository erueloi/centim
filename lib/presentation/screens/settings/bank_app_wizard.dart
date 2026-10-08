import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:centim/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../domain/services/bank_sync_service.dart';

/// Valors que l'owner ha de copiar a l'aplicació d'Enable Banking.
abstract final class BankAppValues {
  static const redirectUrl = 'https://centim-162bd.web.app/bank-callback';
  static const privacyUrl = 'https://centim-162bd.web.app/privacy';
  static const termsUrl = 'https://centim-162bd.web.app/terms';
  static const panelUrl = 'https://enablebanking.com/';
}

/// Assistent de l'owner per configurar l'aplicació d'Enable Banking del grup.
class BankAppWizard extends StatefulWidget {
  final ValueChanged<BankAppSaveResult> onSaved;
  const BankAppWizard({super.key, required this.onSaved});

  @override
  State<BankAppWizard> createState() => _BankAppWizardState();
}

class _BankAppWizardState extends State<BankAppWizard> {
  int _step = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.bankWizardIntro),
        Stepper(
          physics: const NeverScrollableScrollPhysics(),
          currentStep: _step,
          onStepTapped: (step) => setState(() => _step = step),
          controlsBuilder: (context, details) {
            if (details.stepIndex == 2) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(children: [
                FilledButton(
                  onPressed: details.onStepContinue,
                  child: Text(l10n.bankWizardNext),
                ),
                if (details.stepIndex > 0)
                  TextButton(
                    onPressed: details.onStepCancel,
                    child: Text(l10n.bankWizardBack),
                  ),
              ]),
            );
          },
          onStepContinue: () => setState(() => _step = (_step + 1).clamp(0, 2)),
          onStepCancel: () => setState(() => _step = (_step - 1).clamp(0, 2)),
          steps: [
            Step(
              title: Text(l10n.bankWizardStep1Title),
              isActive: _step >= 0,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l10n.bankWizardStep1Body),
                  const SizedBox(height: 12),
                  CopyableValue(
                    label: l10n.bankWizardRedirectUrl,
                    value: BankAppValues.redirectUrl,
                  ),
                  CopyableValue(
                    label: l10n.bankWizardPrivacyUrl,
                    value: BankAppValues.privacyUrl,
                  ),
                  CopyableValue(
                    label: l10n.bankWizardTermsUrl,
                    value: BankAppValues.termsUrl,
                  ),
                  CopyableValue(
                    label: l10n.bankWizardDescription,
                    value: l10n.bankWizardDescriptionValue,
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => launchUrl(Uri.parse(BankAppValues.panelUrl)),
                      icon: const Icon(Icons.open_in_new, size: 18),
                      label: Text(l10n.bankWizardOpenPanel),
                    ),
                  ),
                ],
              ),
            ),
            Step(
              title: Text(l10n.bankWizardStep2Title),
              isActive: _step >= 1,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l10n.bankWizardStep2Body),
                  const SizedBox(height: 8),
                  Text(
                    l10n.bankRestrictedNotice,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            Step(
              title: Text(l10n.bankWizardStep3Title),
              isActive: _step >= 2,
              content: BankCredentialsForm(onSaved: widget.onSaved),
            ),
          ],
        ),
      ],
    );
  }
}

/// Un valor amb botó de copiar.
class CopyableValue extends StatelessWidget {
  final String label;
  final String value;
  const CopyableValue({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      subtitle: SelectableText(value, style: const TextStyle(fontSize: 14)),
      trailing: IconButton(
        tooltip: l10n.bankCopy,
        icon: const Icon(Icons.copy, size: 18),
        onPressed: () async {
          await Clipboard.setData(ClipboardData(text: value));
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.bankCopied)),
            );
          }
        },
      ),
    );
  }
}

/// App id + clau privada (enganxada o pujada) i "Comprova i desa".
///
/// La clau només viu en memòria fins que s'envia a la Function; després de
/// desar-la, el formulari l'oblida.
class BankCredentialsForm extends ConsumerStatefulWidget {
  final ValueChanged<BankAppSaveResult> onSaved;
  const BankCredentialsForm({super.key, required this.onSaved});

  @override
  ConsumerState<BankCredentialsForm> createState() => _BankCredentialsFormState();
}

class _BankCredentialsFormState extends ConsumerState<BankCredentialsForm> {
  final _appIdController = TextEditingController();
  final _pemController = TextEditingController();
  String? _uploadedPem;
  String? _uploadedName;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _appIdController.dispose();
    _pemController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pem', 'key', 'txt'],
      withData: true,
    );
    final file = result?.files.singleOrNull;
    final bytes = file?.bytes;
    if (file == null || bytes == null) return;
    setState(() {
      _uploadedPem = utf8.decode(bytes, allowMalformed: true);
      _uploadedName = file.name;
      _pemController.clear();
      _error = null;
    });
  }

  Future<void> _save() async {
    final pem = _uploadedPem ?? _pemController.text;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final result = await ref.read(bankSyncServiceProvider).saveAppCredentials(
            appId: _appIdController.text.trim(),
            pem: pem,
          );
      if (!mounted) return;
      setState(() {
        _uploadedPem = null;
        _uploadedName = null;
        _pemController.clear();
      });
      widget.onSaved(result);
    } on FirebaseFunctionsException catch (e) {
      if (mounted) setState(() => _error = e.message ?? e.code);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _appIdController,
          decoration: InputDecoration(
            labelText: l10n.bankAppIdLabel,
            hintText: 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx',
          ),
        ),
        const SizedBox(height: 12),
        if (_uploadedName != null)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.key, color: Colors.green),
            title: Text(l10n.bankPemLoaded(_uploadedName!)),
            trailing: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => setState(() {
                _uploadedPem = null;
                _uploadedName = null;
              }),
            ),
          )
        else
          TextField(
            controller: _pemController,
            minLines: 3,
            maxLines: 6,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
            decoration: InputDecoration(
              labelText: l10n.bankPemLabel,
              hintText: '-----BEGIN PRIVATE KEY-----',
              alignLabelWithHint: true,
            ),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _saving ? null : _pickFile,
            icon: const Icon(Icons.upload_file, size: 18),
            label: Text(l10n.bankPemUpload),
          ),
        ),
        Text(
          l10n.bankCredentialsHint,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ],
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.verified_outlined),
          label: Text(l10n.bankCheckAndSave),
        ),
      ],
    );
  }
}
