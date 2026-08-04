import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/services/bank_consent_service.dart';
import '../../domain/services/bank_sync_service.dart';
import '../providers/bank_consent_provider.dart';

class BankConsentBanner extends ConsumerStatefulWidget {
  const BankConsentBanner({super.key});

  @override
  ConsumerState<BankConsentBanner> createState() => _BankConsentBannerState();
}

class _BankConsentBannerState extends ConsumerState<BankConsentBanner> {
  bool _starting = false;

  Future<void> _reconnect(String connectionId) async {
    if (!kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'De moment la reconnexió bancària s’ha de fer des de la versió web.',
          ),
        ),
      );
      return;
    }
    setState(() => _starting = true);
    try {
      final start = await ref.read(bankSyncServiceProvider).startAuth(
            redirectUrl: '${Uri.base.origin}/bank-callback',
            connectionId: connectionId,
          );
      await launchUrl(Uri.parse(start.authUrl), webOnlyWindowName: '_self');
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No s’ha pogut reconnectar: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final alert = ref.watch(bankConsentAlertProvider).valueOrNull;
    if (alert == null) {
      return const SizedBox.shrink();
    }
    final status = alert.status;
    final expired = status.state == BankConsentState.expired;
    final color = expired ? Colors.red : Colors.orange;
    final until = status.validUntil?.toLocal();
    final date = until == null ? '' : DateFormat('dd/MM/yyyy').format(until);
    final text = expired
        ? '${alert.connection.label}: l’accés ha caducat. Cal reconnectar.'
        : '${alert.connection.label}: l’accés caduca en ${status.daysRemaining} '
            'dia${status.daysRemaining == 1 ? '' : 's'} ($date).';

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.key_off_outlined, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(
            onPressed: _starting
                ? null
                : () => _reconnect(alert.connection.connectionId),
            child: _starting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Reconnecta'),
          ),
        ],
      ),
    );
  }
}
